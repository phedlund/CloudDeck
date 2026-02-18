//
//  NewCardSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/7/26.
//

import SwiftUI

struct NewCardSheet: View {
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(\.dismiss) private var dismiss

    let boardID: Int
    let stackID: Int

    @State private var title = ""
    @State private var description = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("", text: $title)
                } header: {
                    Text("Title")
                } footer: {
                    EmptyView()
                }

                Section {
                    TextEditor(text: $description)
                } header: {
                    Text("Description")
                } footer: {
                    EmptyView()
                }            }
            .navigationTitle("New Card")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task {
                            isSaving = true
                            _ = try? await deckAPI.createCard(
                                boardId: boardID,
                                stackId: stackID,
                                title: title,
                                description: description
                            )
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
