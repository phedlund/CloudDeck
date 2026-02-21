//
//  DeckRootView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(AuthenticationManager.self) private var authManager

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @State private var selectedBoardID: Int?
    @State private var selectedStackID: Int?
    @State private var selectedCard: Card?
    @State private var showSettings = false

    private var regularWidthCardBinding: Binding<Card?> {
        Binding(
            get: {
                horizontalSizeClass == .regular ? selectedCard : nil
            },
            set: { selectedCard = $0 }
        )
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
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
                    CardsColumnView(
                        stackID: selectedStackID,
                        selectedCardID: .constant(nil)
                    )
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationSplitView {
                    BoardsColumnView(
                        selectedBoardID: $selectedBoardID,
                        showSettings: $showSettings
                    )
                } detail: {
                    BoardView(
                        boardID: selectedBoardID,
                        selectedCard: $selectedCard
                    )
                    .environment(deckAPI)
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .sheet(item: regularWidthCardBinding) { card in
            CardDetailView(card: card)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }





//        Group {
//            if horizontalSizeClass == .compact {
//                NavigationSplitView(columnVisibility: $columnVisibility) {
//                    BoardsColumnView(
//                        selectedBoardID: $selectedBoardID,
//                        showSettings: $showSettings
//                    )
//                } content: {
//                    StacksColumnView(
//                        boardID: selectedBoardID,
//                        selectedStackID: $selectedStackID
//                    )
//                } detail: {
//                    CardsColumnView(stackID: selectedStackID, selectedCardID: .constant(nil))
//                }
//            } else {
//                NavigationSplitView {
//                    BoardsColumnView(
//                        selectedBoardID: $selectedBoardID,
//                        showSettings: $showSettings
//                    )
//                } detail: {
//                    if let boardID = selectedBoardID {
//                        BoardView(
//                            boardID: boardID,
//                            selectedCardID: $selectedCardID
//                        )
//                    } else {
//                        ContentUnavailableView("Select a Board", systemImage: "rectangle.stack")
//                    }
//                }
//            }
//        }
//        .sheet(isPresented: $showSettings) {
//            SettingsView()
//        }
//        .onChange(of: selectedBoardID) { _, newValue in
//            if newValue != nil {
//                columnVisibility = .doubleColumn
//            }
//        }
//    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Board.self, Stack.self, Card.self], inMemory: true)
}
