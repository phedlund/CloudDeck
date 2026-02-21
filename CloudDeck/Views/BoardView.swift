//
//  BoardView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/19/26.
//

import SwiftData
import SwiftUI

struct BoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeckAPI.self) private var deckAPI

    let boardID: Int?
    @Binding var selectedCard: Card?

    @Query private var boards: [Board]
    @Query private var stacks: [Stack]

    @State private var showNewStackSheet: Bool = false
    @State private var draggedStack: Stack?
    @State private var targetStackIndex: Int? = nil
    @State private var stackHeight: CGFloat = 400 // reasonable default

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
                ForEach(Array(stacks.enumerated()), id: \.element.id) { index, stack in

                    // Vertical insertion line before each stack
                    VerticalInsertionLine(visible: targetStackIndex == index)

                    StackColumnView(stack: stack, onMove: handleMove, selectedCard: $selectedCard)
                        .environment(deckAPI)
                        .frame(width: 320)
                        .opacity(draggedStack?.id == stack.id ? 0.4 : 1)
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear { stackHeight = geo.size.height }
                            }
                        )
                        .draggable(StackDragItem(stackID: stack.id)) {
                            StackDragPreview(title: stack.title)
                                .onAppear { draggedStack = stack }
                                .onDisappear {
                                    draggedStack = nil
                                    targetStackIndex = nil
                                }
                        }
                        .background (
                            GeometryReader { geo in
                                Color.white.opacity(0.001)
                                    .dropDestination(for: StackDragItem.self) { items, location in
                                        guard let item = items.first else { return false }
                                        let insertAt = location.x < geo.size.width / 2
                                            ? index
                                            : index + 1
                                        commitStackReorder(to: insertAt, stackID: item.stackID)
                                        return true
                                    } isTargeted: { isTargeted in
                                        guard isTargeted else {
                                            if targetStackIndex == index || targetStackIndex == index + 1 {
                                                targetStackIndex = nil
                                            }
                                            return
                                        }
                                        targetStackIndex = index
                                    }
                            }
                        )
                }

                // Trailing insertion line + drop target
                Color.white.opacity(0.001)
                    .frame(width: 44, height: stackHeight)  // generous hit area
                    .overlay(VerticalInsertionLine(visible: targetStackIndex == stacks.count))
                    .dropDestination(for: StackDragItem.self) { items, _ in
                        guard let item = items.first else { return false }
                        commitStackReorder(to: stacks.count, stackID: item.stackID)
                        return true
                    } isTargeted: { isTargeted in
                        targetStackIndex = isTargeted ? stacks.count : (targetStackIndex == stacks.count ? nil : targetStackIndex)
                    }
            }
            .padding()
        }
        .dropDestination(for: StackDragItem.self) { _, _ in
            targetStackIndex = nil
            draggedStack = nil
            return false
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

    private func commitStackReorder(to destinationIndex: Int, stackID: Int) {
        defer {
            targetStackIndex = nil
            draggedStack = nil
        }

        var reordered = stacks

        guard let fromIndex = reordered.firstIndex(where: { $0.id == stackID })
        else { return }

        let toIndex = min(destinationIndex, reordered.count)
        reordered.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)

        for reverseIndex in stride(from: reordered.count - 1, through: 0, by: -1) {
            reordered[reverseIndex].order = reverseIndex
        }

        Task {
            for stack in reordered {
                try? await deckAPI.updateStack(
                    boardId: stack.boardId,
                    stackId: stack.id,
                    title: stack.title,
                    order: stack.order
                )
            }
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

struct StackDragPreview: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .padding()
            .frame(width: 320)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4)
    }
}
