//
//  ChipView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/9/26.
//

import SwiftUI

struct ChipView: View {
    let title: String
    let colorHex: String
    var onRemove: () -> Void

    var body: some View {
        let pillColor = Color(hex: colorHex) ?? .secondary.opacity(0.3)
        let textColor = pillColor.accessibleTextColor

        HStack(spacing: 6) {

            Text(title)
                .font(.caption)
                .foregroundStyle(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)   // slightly tighter
                .background(
                    Capsule().fill(pillColor)
                )

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 0)
        .padding(.trailing, 6)
        .background(
            Capsule().fill(.secondary.opacity(0.15))
        )
    }
}
