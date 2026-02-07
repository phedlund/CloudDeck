//
//  CardRow.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import SwiftUI

struct CardRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading) {
            Text(card.title)
                .font(.headline)

            if let desc = card.cardDescription, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}
