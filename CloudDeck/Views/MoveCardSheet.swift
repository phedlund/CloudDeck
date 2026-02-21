//
//  MoveCardSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/16/26.
//

import SwiftData
import SwiftUI

struct MoveCardSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(\.dismiss) private var dismiss

    let card: Card

    @State private var filteredStacks: [Stack]?
    @State private var createACopy: Bool = false
    @State private var isSaving = false

    @Query(filter: #Predicate<Board> { !$0.archived && $0.deletedAt == 0 }, sort: \.title) private var boards: [Board]

    @State private var selectedBoardID: Int?
    @State private var selectedStackID: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Board", selection: $selectedBoardID) {
                        ForEach(boards) { board in
                            Text(board.title)
                                .tag(Optional(board.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .contentShape(Rectangle())
                    if let boardID = selectedBoardID {
                        StacksPicker(boardID: boardID, selectedStackID: $selectedStackID)
                    }
                } header: {
                    Text("Select board and stack")
                } footer: {
                    EmptyView()
                }
                Section {
                    Toggle(isOn: $createACopy) {
                        Text("Make a copy instead of moving")
                    }
                }
            }
            .navigationTitle(Text(card.title))
            .onChange(of: selectedBoardID, initial: false) { oldValue, newValue in
                selectedStackID = nil
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task {
                            if let selectedBoardID, let selectedStackID {
                                isSaving = true
                                if createACopy {
                                    try? await deckAPI.copyCard(card, newBoardId: selectedBoardID, newStackId: selectedStackID)
                                } else {
                                    try? await deckAPI.moveCard(card, newBoardId: selectedBoardID, newStackId: selectedStackID)
                                }
                                dismiss()
                            }
                        }
                    }
                    .disabled(isSaving || selectedBoardID == nil || selectedStackID == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
            }
        }
    }
}

struct StacksPicker: View {
    @Environment(\.modelContext) private var modelContext
    var boardID: Int
    @Binding var selectedStackID: Int?

    @Query private var stacks: [Stack]

    init(boardID: Int, selectedStackID: Binding<Int?>) {
        self.boardID = boardID
        self._selectedStackID = selectedStackID
        _stacks = Query(filter: #Predicate<Stack> { $0.boardId == boardID }, sort: \.order)
    }

    var body: some View {
        Picker("Stack", selection: $selectedStackID) {
            ForEach(stacks) { stack in
                Text(stack.title)
                    .tag(Optional(stack.id))
            }
        }
    }
}
