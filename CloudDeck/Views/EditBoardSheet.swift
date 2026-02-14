//
//  EditBoardSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/13/26.
//

import SwiftUI

struct EditBoardSheet: View {
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var color: Color = .random()
    @State private var colorHex: String = ""
    @State private var isSaving = false

    @FocusState private var isTextFieldFocused: Bool

    var board: Board

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
                        ForEach(board.labels.sorted(by: { $0.title < $1.title } )) { label in
                            HStack(spacing: 12) {
                                ChipView(title: label.title, colorHex: label.color)
                                Spacer()
                                Button {
                                    Task {
                    //
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .labelStyle(.iconOnly)
                                }
                                Button(role: .destructive) {
                                    Task {
                    //
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .labelStyle(.iconOnly)
                                }
                            }
                        }
                        Button {
                            //
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
//                            try? await deckAPI.createBoard(title: title, colorHex: colorHex)
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
