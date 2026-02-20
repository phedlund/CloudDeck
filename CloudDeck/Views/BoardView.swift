//
//  BoardView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/19/26.
//

import SwiftData
import SwiftUI

struct BoardView: View {
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
                    StackColumnView(stack: stack, onMove: move, selectedCard: $selectedCard)
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

    private func move(cardID: Int, to targetStack: Stack, before targetCardID: Int?) {

//        var revisedCards = cards
//        revisedCards.move(fromOffsets: source, toOffset: destination)
//        for reverseIndex in stride(from: revisedCards.count - 1, through: 0, by: -1) {
//            revisedCards[reverseIndex].order = reverseIndex
//        }
//        for card in revisedCards {
//            Task {
//                try? await self.deckAPI.updateCard(card)
//            }
//        }
//
//
//
//
        guard let card = findCard(by: cardID),
              let sourceStack = stacks.first(where: { $0.id == card.stackId })
        else { return }

        // Remove from source
        sourceStack.cards.removeAll { $0.id == cardID }

        // Update stack if needed
        card.stackId = targetStack.id

        if let targetCardID,
           let index = targetStack.cards.firstIndex(where: { $0.id == targetCardID }) {
            targetStack.cards.insert(card, at: index)
        } else {
            targetStack.cards.append(card)
        }

        normalizeOrder(in: sourceStack)

        if sourceStack.id != targetStack.id {
            normalizeOrder(in: targetStack)
        }
    }

    private func normalizeOrder(in stack: Stack) {
        for (index, card) in stack.cards.enumerated() {
            card.order = Int(index)
        }
    }

    private func findCard(by id: Int) -> Card? {
        stacks
            .flatMap { $0.cards }
            .first { $0.id == id }
    }
}
