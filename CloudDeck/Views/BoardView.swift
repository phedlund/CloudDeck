//
//  BoardView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/19/26.
//

import SwiftData
import SwiftUI

struct BoardView: View {
    @Environment(DeckAPI.self) private var deckAPI

    let boardID: Int?
    @Binding var selectedCard: Card?

    @Query private var boards: [Board]
    @Query private var stacks: [Stack]

    @State private var showNewStackSheet: Bool = false

    init(boardID: Int?, selectedCard: Binding<Card?>) {
        self.boardID = boardID
        self._selectedCard = selectedCard

        if let boardID {
            _stacks = Query(filter: #Predicate<Stack> { $0.boardId == boardID }, sort: \.order)
            _boards = Query(filter: #Predicate<Board> { $0.id == boardID } )
        } else {
            _stacks = Query(filter: #Predicate<Stack> { _ in false })
            _boards = Query(filter: #Predicate<Board> { _ in false })
        }
    }

    private var boardTitle: String {
        boards.first?.title ?? "Lists"
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 16) {
                ForEach(stacks) { stack in
                    StackColumnView(stack: stack, onMove: handleMove, selectedCard: $selectedCard)
                        .frame(width: 320)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(boardTitle)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showNewStackSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(boardID == nil)
            }
        }
        .sheet(isPresented: $showNewStackSheet) {
            NewStackSheet(boardId: boardID ?? 0)
        }
    }

    private func handleMove(cardID: Int, toStack: Stack, toIndex: Int) {
        // Find the card across all stacks
        guard let card = stacks.flatMap(\.cards).first(where: { $0.id == cardID })
        else { return }
        
        let sourceStack = stacks.first(where: { $0.id == card.stackId })
        
        // Update the card's stack
        card.stackId = toStack.id
        card.order = toIndex
        
        // Re-sequence the source stack
        if let sourceStack {
            let sourceCards = sourceStack.cards
                .filter { $0.id != cardID }
                .sorted { $0.order < $1.order }
            for reverseIndex in stride(from: sourceCards.count - 1, through: 0, by: -1) {
                sourceCards[reverseIndex].order = reverseIndex
            }
            Task {
                for card in sourceCards {
                    try? await deckAPI.updateCard(card)
                }
            }
        }
        
        // Re-sequence the destination stack (insert at toIndex)
        var destCards = toStack.cards
            .filter { $0.id != cardID }
            .sorted { $0.order < $1.order }
        destCards.insert(card, at: min(toIndex, destCards.count))
        for reverseIndex in stride(from: destCards.count - 1, through: 0, by: -1) {
            destCards[reverseIndex].order = reverseIndex
        }
        
        Task {
            for card in destCards {
                try? await deckAPI.updateCard(card)
            }
        }
    }
}
