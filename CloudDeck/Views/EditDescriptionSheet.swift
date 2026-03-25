//
//  DescriptionEditSheet.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 3/23/26.
//

import MDTextEditor
import SwiftUI

struct EditDescriptionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var markdownSource: String?
    @State private var attributedEditBuffer: AttributedString = ""
    @State private var selection = AttributedTextSelection()

    var body: some View {
        NavigationStack {
            Group {
                MDTextEditor(text: $attributedEditBuffer, selection: $selection)
                    .padding(.vertical)
                    .task {
                        attributedEditBuffer = AttributedString(markdownSource ?? "")
                    }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(role: .confirm) {
                                markdownSource = String(attributedEditBuffer.characters)
                                dismiss()
                            }
                            .disabled(markdownSource == String(attributedEditBuffer.characters))
                        }

                        ToolbarItem(placement: .cancellationAction) {
                            Button(role: .cancel) {
                                attributedEditBuffer = AttributedString(markdownSource ?? "")
                                dismiss()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    EditDescriptionSheet(markdownSource: .constant(""))
}
