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

    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: Double
        let length = hexSanitized.count

        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        } else {
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    var hexString: String {

        let uiColor = UIColor(self), cgColor = uiColor.cgColor, cgColorInRGB = cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)!
        let colorRef = cgColorInRGB.components
        let r = colorRef?[0] ?? 0
        let g = colorRef?[1] ?? 0
        let b = ((colorRef?.count ?? 0) > 2 ? colorRef?[2] : g) ?? 0
        let a = cgColor.alpha

        var color = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )

        if a < 1 {
            color += String(format: "%02lX", lroundf(Float(a * 255)))
        }

        return color
    }

}
