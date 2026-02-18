//
//  CardsColumnView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

import SwiftUI
import SwiftData

struct SheetItem: Identifiable {
    let id: Int
}

struct CardsColumnView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(AuthenticationManager.self) private var authManager
    let stackID: Int?
    @State private var activeSheet: SheetItem?
    @State private var showNewCardSheet = false
    @State private var cardToMove: Card? = nil

    @Query private var cards: [Card]
    @Query private var stacks: [Stack]

    init(stackID: Int?, selectedCardID: Binding<Int?>) {
        self.stackID = stackID

        if let stackID {
            _cards = Query(filter: #Predicate<Card> { $0.stackId == stackID && !$0.archived }, sort: \.order)
            _stacks = Query(filter: #Predicate<Stack> { $0.id == stackID } )
        } else {
            _cards = Query(filter: #Predicate<Card> { _ in false })
            _stacks = Query(filter: #Predicate<Stack> { _ in false })
        }
    }

    private var stackTitle: String {
        stacks.first?.title ?? "Cards"
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(cards, id: \.self) { card in
                    CardRow(card: card)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            activeSheet = SheetItem(id: card.id)
                        }
                        .contextMenu {
                            Button {
                                if let username = authManager.currentAccount()?.username {
                                    Task {
                                        let backgroundActor = DeckModelActor(modelContainer: modelContext.container)
                                        if let stack = await backgroundActor.fetchStack(id: card.stackId) {
                                            if let board = await backgroundActor.fetchBoard(id: stack.boardId),
                                               let me = board.users.filter(
                                                { $0.uid == username }
                                               ).first {

                                                try? await deckAPI.assignUser(card: card, user: me)
                                            }

                                        }
                                    }
                                }
                            } label: {
                                Label("Assign to me", systemImage: "person")
                            }
                            //                        .disabled(true)
                            Button {
                                Task {
                                    try? await deckAPI.setCardDone(card: card, done: true)
                                }
                            } label: {
                                Label("Mark as done", systemImage: "checkmark")
                            }
                            .disabled(card.doneAt != nil)
                            Button {
                                cardToMove = card
                            } label: {
                                Label("Move/Copy", systemImage: "square.and.arrow.up.on.square")
                            }
                            .disabled(false)
                            Button {
                                Task {
                                    try? await deckAPI.setCardArchived(card: card, archived: true)
                                }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .disabled(card.archived)
                            Button(role: .destructive) {
                                Task {
                                    try? await deckAPI.deleteCard(boardId: card.stack?.boardId ?? 0, stackId: card.stack?.id ?? 0, cardId: card.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove(perform: move)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(stackTitle)
        .sheet(item: $activeSheet) {
            CardDetailSheet(cardID: $0.id)
        }
        .sheet(item: $cardToMove) {
            MoveCardSheet(card: $0)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewCardSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewCardSheet) {
            if let stack = stacks.first {
                NewCardSheet(boardID: stack.boardId, stackID: stack.id)
            }
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        var revisedCards = cards
        revisedCards.move(fromOffsets: source, toOffset: destination)
        for reverseIndex in stride(from: revisedCards.count - 1, through: 0, by: -1) {
            revisedCards[reverseIndex].order = reverseIndex
        }
        for card in revisedCards {
            Task {
                try? await self.deckAPI.updateCard(card)
            }
        }
    }

}
