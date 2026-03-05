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

    @AppStorage(Constants.Settings.selectedBoard) private var selectedBoard: Int?

    @State private var columnVisibility = NavigationSplitViewVisibility.all

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

    private var boardSelectionBinding: Binding<Int?> {
        Binding<Int?>(
            get: { self.selectedBoard },
            set: { newValue in
                self.selectedBoard = newValue
            }
        )
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                NavigationSplitView {
                    BoardsColumnView(
                        selectedBoardID: boardSelectionBinding,
                        showSettings: $showSettings
                    )
                } content: {
                    StacksColumnView(
                        boardID: boardSelectionBinding.wrappedValue,
                        selectedStackID: $selectedStackID
                    )
                } detail: {
                    EmptyView()
//                    CardsColumnView(
//                        stackID: selectedStackID,
//                        selectedCardID: .constant(nil)
//                    )
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationSplitView {
                    BoardsColumnView(
                        selectedBoardID: boardSelectionBinding,
                        showSettings: $showSettings
                    )
                } detail: {
                    BoardView(
                        boardID: boardSelectionBinding.wrappedValue,
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
