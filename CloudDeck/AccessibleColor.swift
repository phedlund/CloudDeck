//
//  AccessibleColor.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftUI

extension Color {
    var accessibleTextColor: Color {
        // 1. Get the components regardless of platform
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        #if os(macOS)
        // macOS uses NSColor
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .black
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        // iOS/watchOS/tvOS use UIColor
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        // 2. Standard Relative Luminance Formula
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

        // 3. Return black for light backgrounds, white for dark
        return luminance > 0.5 ? .black : .white
    }
}
