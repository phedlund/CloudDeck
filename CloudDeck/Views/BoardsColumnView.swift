//
//  BoardsColumnView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

import SwiftUI
import SwiftData

struct BoardsColumnView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeckAPI.self) private var deckAPI

    @Binding var selectedBoardID: Int?
    @Binding var showSettings: Bool

    @State private var showNewBoardSheet: Bool = false
    @State private var boardToShowDetails: Board? = nil

    @Query(filter: #Predicate<Board> { !$0.archived && $0.deletedAt == nil }, sort: \.title) private var boards: [Board]

    var body: some View {
        Group {
            if boards.isEmpty {
                ContentUnavailableView {
                    Label("No Boards Available", systemImage: "list.dash")
                } description: {
                    Text("Tap the sync button \(Image(systemName: "arrow.clockwise")) to download your boards. Then select a board to show its lists.")
                }
            } else {
                List(boards, selection: $selectedBoardID) { board in
                    Label {
                        Text(board.title)
                    } icon: {
                        Circle().fill(Color(hex: board.color) ?? .secondary)
                    }
                    .tag(board.id)
                    .contextMenu {
                        Button {
                            boardToShowDetails = board
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            Task {
                                try? await deckAPI.updateBoard(boardId: board.id, title: board.title, color: board.color, archived: true)
                            }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .disabled(board.archived)
                        Button(role: .destructive) {
                            Task {
                                try? await deckAPI.deleteBoard(boardId: board.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
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

                Button {
                    showNewBoardSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewBoardSheet) {
            NewBoardSheet()
        }
        .sheet(item: $boardToShowDetails) { board in
            EditBoardSheet(board: board)
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
