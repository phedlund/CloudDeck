//
//  DeckRootView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(AuthenticationManager.self) private var authManager

    @State private var selectedBoard: Board?
    @State private var selectedStack: Stack?
    @State private var selectedCard: Card?

    @State private var showSettings = false

    // MARK: Queries

    @Query(filter: #Predicate<Board> { !$0.archived },
           sort: \.title)
    private var boards: [Board]

    @Query private var stacks: [Stack]
    @Query private var cards: [Card]

    var body: some View {
        NavigationSplitView {
            // MARK: Boards
            List(boards, selection: $selectedBoard) { board in
                Text(board.title)
            }
            .navigationTitle("Boards")
            .refreshable {
                Task {
                    do {
                        try await deckAPI.sync()
                    } catch {
                        //
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task {
                            do {
                                try await deckAPI.sync()
                            } catch {
                                //
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        } content: {
            // MARK: Stacks
            List(stacks, selection: $selectedStack) { stack in
                Text(stack.title)
            }
            .navigationTitle(selectedBoard?.title ?? "Stacks")
        } detail: {
            // MARK: Cards
            List(cards, selection: $selectedCard) { card in
                VStack(alignment: .leading) {
                    Text(card.title)
                        .font(.headline)

                    if let desc = card.cardDescription {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(selectedStack?.title ?? "Cards")
        }
        .onChange(of: selectedBoard) {
            selectedStack = nil
            selectedCard = nil
//            updateStacksQuery()
        }
        .onChange(of: selectedStack) {
            selectedCard = nil
//            updateCardsQuery()
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
