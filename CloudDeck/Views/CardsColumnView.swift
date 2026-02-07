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
    let stackID: Int?
    @State private var activeSheet: SheetItem?

    @Query private var cards: [Card]
    @Query private var stacks: [Stack]

    init(stackID: Int?, selectedCardID: Binding<Int?>) {
        self.stackID = stackID

        if let stackID {
            _cards = Query(filter: #Predicate<Card> { $0.stackId == stackID }, sort: \.order)
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
        List(cards) { card in
            CardRow(card: card)
                .contentShape(Rectangle())
                .onTapGesture {
                    activeSheet = SheetItem(id: card.id)
                }
        }
        .navigationTitle(stackTitle)
        .sheet(item: $activeSheet) {
            CardDetailSheet(cardID: $0.id)
        }
    }
}

extension Int: @retroactive Identifiable {
    public var id: Self { self }
}
