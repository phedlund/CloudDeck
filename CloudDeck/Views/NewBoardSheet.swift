//
//  NewCardSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/7/26.
//

import SwiftUI

enum TitleColorSheetType {
    case newBoard
    case newLabel(boardID: Int)
    case editLabel(label: DeckLabel)
}

struct NewBoardSheet: View {
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(\.dismiss) private var dismiss

    let titleColorSheetType: TitleColorSheetType

    @State private var title = ""
    @State private var color: Color = .random()
    @State private var colorHex: String = ""
    @State private var isSaving = false

    @FocusState private var isTextFieldFocused: Bool

    private var navTitle: String {
        switch titleColorSheetType {
        case .newBoard:
            return "New Board"
        case .newLabel:
            return "New Label"
        case .editLabel:
            return "Edit Label"
        }
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
            }
            .navigationTitle(navTitle)
            .task {
                isTextFieldFocused = true
                switch titleColorSheetType {
                case .newBoard, .newLabel:
                    break
                case .editLabel(let label):
                    title = label.title
                    color = Color(hex: label.color) ?? .random()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task {
                            isSaving = true
                            switch titleColorSheetType {
                            case .newBoard:
                                try? await deckAPI.createBoard(title: title, colorHex: colorHex)
                            case .newLabel(let boardID):
                                try? await deckAPI.createBoardLabel(boardId: boardID, title: title, color: colorHex)
                            case .editLabel(let label):
                                try? await deckAPI.updateBoardLabel(boardId: label.boardId, labelId: label.id, title: title, color: colorHex)
                            }
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
            }
        }
        .onChange(of: color, initial: true) {_, newValue in
            colorHex = newValue.hexString
        }
    }
}
