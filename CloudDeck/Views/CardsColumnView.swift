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
    @State private var draggedCard: Card?
    @State private var targetIndex: Int? = nil

    @Query private var cards: [Card]
    @Query private var stacks: [Stack]

    init(stackID: Int?, selectedCardID: Binding<Int?>) {
        self.stackID = stackID

        if let stackID {
            _cards = Query(filter: #Predicate<Card> { $0.stackId == stackID && !$0.archived && $0.deletedAt == nil }, sort: \.order)
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
                    LazyVStack(spacing: 0) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in

                            InsertionLine(visible: targetIndex == index)

                            CardRow(card: card)
                                .padding(.vertical, 6)
                                .opacity(draggedCard?.id == card.id ? 0.4 : 1)
                                .draggable(CardDragItem(cardID: card.id)) {
                                    CardRow(card: card)
                                        .frame(width: 300)
                                        .onAppear { draggedCard = card }
                                        .onDisappear {
                                            // Drag ended — reset regardless of how it ended
                                            draggedCard = nil
                                            targetIndex = nil
                                        }
                                }
                                .onTapGesture {
                                    activeSheet = SheetItem(id: card.id)
                                }
                                .contextMenu {
                                    CardContextMenu(cardToMove: $cardToMove, card: card)
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
                                                targetIndex = index
                                            }
                                    }
                                )
                        }

                        Color.white.opacity(0.001)
                            .frame(height: 44)  // generous hit area
                            .overlay(InsertionLine(visible: targetIndex == cards.count))
                            .dropDestination(for: CardDragItem.self) { items, _ in
                                guard let item = items.first else { return false }
                                commitReorder(to: cards.count, cardID: item.cardID)
                                return true
                            } isTargeted: { isTargeted in
                                targetIndex = isTargeted ? cards.count : (targetIndex == cards.count ? nil : targetIndex)
                            }

                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .dropDestination(for: CardDragItem.self) { _, _ in
                    targetIndex = nil
                    draggedCard = nil
                    return false
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

    private func commitReorder(to destinationIndex: Int, cardID: Int) {
        defer {
            targetIndex = nil
            draggedCard = nil
        }

        var reordered = cards

        guard let fromIndex = reordered.firstIndex(where: { $0.id == cardID })
        else { return }

        let toIndex = min(destinationIndex, reordered.count)

        reordered.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)

        for reverseIndex in stride(from: reordered.count - 1, through: 0, by: -1) {
            reordered[reverseIndex].order = reverseIndex
        }

        Task {
            for card in reordered {
                try? await deckAPI.updateCard(card)
            }
        }
    }

}
