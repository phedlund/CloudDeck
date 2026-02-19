//
//  DeckRootView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(AuthenticationManager.self) private var authManager

        @State private var selectedBoardID: Int?
        @State private var selectedStackID: Int?

        @State private var showSettings = false

        var body: some View {
            NavigationSplitView {
                BoardsColumnView(
                    selectedBoardID: $selectedBoardID,
                    showSettings: $showSettings
                )
            } content: {
                StacksColumnView(
                    boardID: selectedBoardID,
                    selectedStackID: $selectedStackID
                )
            } detail: {
                CardsColumnView(stackID: selectedStackID, selectedCardID: .constant(nil))
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
}

#Preview {
    ContentView()
        .modelContainer(for: [Board.self, Stack.self, Card.self], inMemory: true)
}
