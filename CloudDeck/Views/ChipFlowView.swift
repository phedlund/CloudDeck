//
//  ChipFlowView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/9/26.
//

import SwiftUI

struct ChipFlowView<Data: RandomAccessCollection, Content: View, Trailing: View>: View
where Data.Element: Identifiable {

    let data: Data
    let content: (Data.Element) -> Content
    let trailing: Trailing

    init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.data = data
        self.content = content
        self.trailing = trailing()
    }

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(data) { element in
                content(element)
            }
            trailing
        }
    }
}
