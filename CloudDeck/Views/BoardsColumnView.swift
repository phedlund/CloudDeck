//
//  BoardsColumnView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

import SwiftUI
import SwiftData

struct BoardsColumnView: View {
    @Environment(DeckAPI.self) private var deckAPI

    @Binding var selectedBoardID: Int?
    @Binding var showSettings: Bool

    @Query(
        filter: #Predicate<Board> { !$0.archived },
        sort: \.title
    )
    private var boards: [Board]

    var body: some View {
        List(boards, selection: $selectedBoardID) { board in
            Label {
                Text(board.title)
            } icon: {
                Circle().fill(Color(hex: board.colorHex) ?? .secondary)
            }
            .tag(board.id)
        }
        .navigationTitle("Boards")
        .refreshable {
            try? await deckAPI.sync()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task { try? await deckAPI.sync() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }


private func sync() async {
        do {
            try await deckAPI.sync()
        } catch {
            // handle later
        }
    }
}
