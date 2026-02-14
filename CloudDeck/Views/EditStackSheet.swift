//
//  EditStackSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/13/26.
//

import SwiftUI

struct EditStackSheet: View {
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var isSaving = false

    @FocusState private var isTextFieldFocused: Bool

    var stack: Stack

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("", text: $title)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Title")
                } footer: {
                    EmptyView()
                }
            }
            .navigationTitle("Edit Stack")
            .task {
                title = stack.title
                isTextFieldFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task {
                            isSaving = true
                            try? await deckAPI.updateStack(boardId: stack.boardId, stackId: stack.id, title: title, order: stack.order)
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
    }
}
