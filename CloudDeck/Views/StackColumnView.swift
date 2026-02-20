//
//  StackColumnView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/19/26.
//

import SwiftData
import SwiftUI

struct StackColumnView: View {
    @Environment(DeckAPI.self) private var deckAPI

    let stack: Stack
    let onMove: (Int, Stack, Int?) -> Void
    @Binding var selectedCard: Card?

    @State private var showNewCardSheet = false
    @State private var stackToShowDetails: Stack? = nil
    @State private var cardToMove: Card? = nil
    @State private var draggedCard: Card?
    @State private var targetIndex: Int? = nil

    @Query private var cards: [Card]

    init(stack: Stack, onMove: @escaping (Int, Stack, Int?) -> Void, selectedCard: Binding<Card?>) {
        self.stack = stack
        self.onMove = onMove
        self._selectedCard = selectedCard
        let stackId = stack.id
        _cards = Query(filter: #Predicate<Card> { $0.stackId == stackId && !$0.archived }, sort: \.order)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(stack.title)
                    .font(.headline)
                    .padding(.horizontal)
                Spacer()
                Menu {
                    Button {
                        stackToShowDetails = stack
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        //
                    } label: {
                        Label("Archive all cards", systemImage: "archivebox")
                    }
                    .disabled(true)
                    Button(role: .destructive) {
                        Task {
                            try? await deckAPI.deleteStack(boardId: stack.boardId, stackId: stack.id)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Label {
                        Text("Edit List")
                    } icon: {
                        Image(systemName: "ellipsis")
                    }
                    .labelStyle(.iconOnly)
                    .accentColor(.primary)
                }
                Button {
                    showNewCardSheet = true
                } label: {
                    Label {
                        Text("Add Card")
                    } icon: {
                        Image(systemName: "rectangle.badge.plus")
                    }
                    .labelStyle(.iconOnly)
                    .accentColor(.primary)
                }
            }
            .padding()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in

                        InsertionLine(visible: targetIndex == index)

                        CardRow(card: card)
                            .padding(.vertical, 6)
//                            .padding(.horizontal)
                            .opacity(draggedCard?.id == card.id ? 0.4 : 1)
                            .draggable(CardDragItem(cardID: card.id)) {
                                CardRow(card: card)
                                    .frame(width: 300)
                                    .onAppear { draggedCard = card }
                            }
                            .background(
                                GeometryReader { geo in
                                    Color.white.opacity(0.001)
                                        .dropDestination(for: CardDragItem.self) { items, location in
                                            guard let item = items.first else { return false }
                                            let insertAt = location.y < geo.size.height / 2
                                                ? index        // top half → insert above
                                                : index + 1    // bottom half → insert below
                                            commitReorder(to: insertAt, cardID: item.cardID)
                                            return true
                                        } isTargeted: { isTargeted in
                                            guard isTargeted else {
                                                if targetIndex == index || targetIndex == index + 1 {
                                                    targetIndex = nil
                                                }
                                                return
                                            }
                                            // Use index not index+1, so top half shows line above
                                            targetIndex = index
                                        }
                                }
                            )
                    }

                    InsertionLine(visible: targetIndex == cards.count)
                }
                .padding(.horizontal)
            }
            .dropDestination(for: CardDragItem.self) { _, _ in
                targetIndex = nil
                draggedCard = nil
                return false
            }
        }
        .frame(maxHeight: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showNewCardSheet) {
            NewCardSheet(boardID: stack.boardId, stackID: stack.id)
        }
        .sheet(item: $stackToShowDetails) { stack in
            EditStackSheet(stack: stack)
        }
        .sheet(item: $cardToMove) {
            MoveCardSheet(card: $0)
        }
    }

    private func commitReorder(to destinationIndex: Int, cardID: Int) {
        defer {
            targetIndex = nil
            draggedCard = nil
        }

        var reordered = cards

        guard let fromIndex = reordered.firstIndex(where: { $0.id == cardID })
        else { return }

        let toIndex = min(destinationIndex, reordered.count)

        // No +1 adjustment — move(fromOffsets:toOffset:) handles it correctly as-is
        reordered.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)

        for reverseIndex in stride(from: reordered.count - 1, through: 0, by: -1) {
            reordered[reverseIndex].order = reverseIndex
        }

        Task {
            for card in reordered {
                try? await deckAPI.updateCard(card)
            }
        }
    }}

struct InsertionLine: View {
    let visible: Bool

    var body: some View {
        Rectangle()
            .fill(visible ? Color.accentColor : Color.clear)
            .frame(maxWidth: .infinity)
            .frame(height: 2)
            .animation(.easeInOut(duration: 0.15), value: visible)
    }
}
