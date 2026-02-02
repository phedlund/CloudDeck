//
//  DeckRootView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftData
import SwiftUI

struct DeckRootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedBoard: DeckBoard?
    @State private var selectedStack: DeckStack?
    @State private var selectedCard: DeckCard?

    @State private var showSettings = false

    // MARK: Queries

    @Query(filter: #Predicate<DeckBoard> { !$0.archived },
           sort: \.title)
    private var boards: [DeckBoard]

    @Query private var stacks: [DeckStack]
    @Query private var cards: [DeckCard]

    var body: some View {
        NavigationSplitView {
            // MARK: Boards
            List(boards, selection: $selectedBoard) { board in
                Text(board.title)
            }
            .navigationTitle("Boards")
            .refreshable {
                let actor = DeckSyncActor(modelContainer: modelContext.container)
                try? await actor.syncBoards()
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let actor = DeckSyncActor(modelContainer: modelContext.container)
                            try? await actor.syncBoards()
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
