//
//  CardDetailSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import SwiftData
import SwiftUI

struct CardDetailSheet: View {
    let cardID: Int

    @Environment(\.modelContext) private var modelContext

    @Query private var cards: [Card]

    init(cardID: Int) {
        self.cardID = cardID
        _cards = Query(
            filter: #Predicate<Card> { $0.id == cardID }
        )
    }

    private var card: Card? { cards.first }

    var body: some View {
        NavigationStack {
            if let card {
                CardDetailView(card: card)
            } else {
                ContentUnavailableView("Card not found", systemImage: "exclamationmark.triangle")
            }
        }
    }
}
