//
//  EditBoardSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/13/26.
//

import SwiftData
import SwiftUI

struct EditBoardSheet: View {
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var color: Color = .random()
    @State private var colorHex: String = ""
    @State private var isSaving = false

    @FocusState private var isTextFieldFocused: Bool

    @State private var showNewLabelSheet: Bool = false
    @State private var labelToShowDetails: DeckLabel? = nil

    var board: Board

    @Query private var labels: [DeckLabel]

    init(board: Board) {
        self.board = board
        let boardId = board.id
        _labels = Query(filter: #Predicate<DeckLabel> { $0.boardId == boardId }, sort: \.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("", text: $title)
                        .focused($isTextFieldFocused)
                    ColorPicker(selection: $color, supportsOpacity: false) {
                        Text("Color")
                    }
                } header: {
                    Text("Title")
                } footer: {
                    EmptyView()
                }
                Section {
                    List {
                        ForEach(labels) { label in
                            HStack(spacing: 12) {
                                ChipView(title: label.title, colorHex: label.color)
                                Spacer()
                                Button {
                                    labelToShowDetails = label
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .labelStyle(.iconOnly)
                                }
                                Button(role: .destructive) {
                                    labelToShowDetails = nil
                                    Task {
                                        try? await deckAPI.deleteBoardLabel(boardId: label.boardId, labelId: label.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .labelStyle(.iconOnly)
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                        Button {
                            showNewLabelSheet = true
                        } label: {
                            Text("Add Label")
                        }
                    }
                } header: {
                    Text("Labels")
                } footer: {
                    EmptyView()
                }
            }
            .onAppear {
                title = board.title
                color = Color(hex: board.color) ?? Color.secondary
                colorHex = board.color
            }
            .navigationTitle("Edit Board")
            .task {
                isTextFieldFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task {
                            isSaving = true
                            try? await deckAPI.updateBoard(boardId: board.id, title: title, color: colorHex, archived: board.archived)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        showNewLabelSheet = false
                        labelToShowDetails = nil
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: color, initial: true) {_, newValue in
            colorHex = newValue.hexString
        }
        .sheet(isPresented: $showNewLabelSheet) {
            NewBoardSheet(titleColorSheetType: .newLabel(boardID: board.id))
        }
        .sheet(item: $labelToShowDetails) { label in
            NewBoardSheet(titleColorSheetType: .editLabel(label: label))
        }

    }
}
