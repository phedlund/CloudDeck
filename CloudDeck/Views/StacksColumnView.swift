//
//  StacksColumnView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

import SwiftUI
import SwiftData

struct StacksColumnView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeckAPI.self) private var deckAPI

    let boardID: Int?
    @Binding var selectedStackID: Int?

    @Query private var boards: [Board]
    @Query private var stacks: [Stack]
    @Query private var cards: [Card]

    @State private var showNewStackSheet: Bool = false
    @State private var stackToShowDetails: Stack? = nil

    init(boardID: Int?, selectedStackID: Binding<Int?>) {
        self.boardID = boardID
        self._selectedStackID = selectedStackID

        if let boardID {
            _stacks = Query(filter: #Predicate<Stack> { $0.boardId == boardID && $0.deletedAt == nil }, sort: \.order)
            _boards = Query(filter: #Predicate<Board> { $0.id == boardID } )

        } else {
            _stacks = Query(filter: #Predicate<Stack> { _ in false })
            _boards = Query(filter: #Predicate<Board> { _ in false })
        }
    }

    private var boardTitle: String {
        boards.first?.title ?? "Lists"
    }

    private var boardColor: Color {
        var result = Color.clear
        if let hexString = boards.first?.color {
            result = Color(hex: hexString) ?? .clear
        }
        return result
    }

    private var cardCounts: [Int: Int] {
        Dictionary(grouping: cards.filter( { $0.archived == false }), by: \.stackId)
            .mapValues(\.count)
    }

    var body: some View {
        Group {
            if stacks.isEmpty {
                ContentUnavailableView {
                    Label("No Lists Available", systemImage: "list.dash")
                } description: {
                    Text("Tap the plus button \(Image(systemName: "plus")) to add one.")
                }
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        Capsule()
                            .fill(boardColor)
                            .frame(height: 9)
                        ForEach(Array(stacks.enumerated()), id: \.element.id) { index, stack in
                            NavigationLink(value: stack.id) {
                                StackRow(stack: stack)
                                    .tag(stack.id)
                                    .padding(.vertical, 6)
                                    .contextMenu {
                                        Button {
                                            stackToShowDetails = stack
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button {
                                            //
                                        } label: {
                                            Label("Archive all cards", systemImage: "archivebox")
                                        }
                                        .disabled(true)
                                        Button(role: .destructive) {
                                            Task {
                                                try? await deckAPI.deleteStack(boardId: stack.boardId, stackId: stack.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .navigationDestination(for: Int.self) { item in
                    CardsColumnView(stackID: item, selectedCardID: $selectedStackID)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(boardTitle)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showNewStackSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewStackSheet) {
            NewStackSheet(boardId: boardID ?? 0)
        }
        .sheet(item: $stackToShowDetails) { stack in
            EditStackSheet(stack: stack)
        }

    }
}
