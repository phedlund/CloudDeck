//
//  ChipFlowView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/9/26.
//

import SwiftUI

struct ChipFlowView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {

    let data: Data
    let content: (Data.Element) -> Content

    init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
    }

    var body: some View {
        ChipFlowLayout {
            ForEach(data) { element in
                content(element)
            }
        }
    }
}
