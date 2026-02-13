//
//  NewCardSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/7/26.
//

import SwiftUI

struct NewBoardSheet: View {
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var color: Color = .random()
    @State private var colorHex: String = ""
    @State private var isSaving = false

    @FocusState private var isTextFieldFocused: Bool

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
            .navigationTitle("New Board")
            .task {
                isTextFieldFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task {
                            isSaving = true
                            try? await deckAPI.createBoard(title: title, colorHex: colorHex)
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
