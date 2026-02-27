//
//  StackRow.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/26/26.
//

import SwiftData
import SwiftUI

struct StackRow: View {
    let stack: Stack

    @Query private var cards: [Card]

    private var cardCounts: [Int: Int] {
        Dictionary(grouping: cards.filter( { $0.archived == false }), by: \.stackId)
            .mapValues(\.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(stack.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(.cardCount(cardCounts[stack.id, default: 0]))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
