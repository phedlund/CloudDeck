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
        Group {
            if cards.isEmpty {
                ContentUnavailableView {
                    Label("No Cards Available", systemImage: "list.dash.header.rectangle")
                } description: {
                    Text("Tap the plus button \(Image(systemName: "plus")) to add one.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cards, id: \.self) { card in
                            CardRow(card: card)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    activeSheet = SheetItem(id: card.id)
                                }
                                .contextMenu {
                                    CardContextMenu(cardToMove: $cardToMove, card: card)
                                }
                        }
                        .onMove(perform: move)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
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
