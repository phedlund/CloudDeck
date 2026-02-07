//
//  TagFlowView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import SwiftUI

struct TagFlowView: View {
    let tags: [DeckLabel]

    var body: some View {
        FlowLayout(spacing: 8, rowSpacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagChip(tag: tag)
            }
        }
    }
}
