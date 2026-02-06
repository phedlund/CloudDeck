//
//  TagChip.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import SwiftUI

struct TagChip: View {
    let tag: DeckLabel

    var body: some View {
        Text(tag.title)
            .font(.caption)
            .foregroundColor(.white) // Set text color
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: tag.color) ?? .secondary, in: Capsule())
            .clipShape(Capsule())
    }
}
