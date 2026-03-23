//
//  CardDescriptionSection.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 3/10/26.
//

import MDTextEditor
import SwiftUI
import Textual

struct CardDescriptionSection: View {
    @Binding var markdownSource: String?
    @State private var isEditing = false
    @State private var attributedEditBuffer: AttributedString = ""
    @State private var selection = AttributedTextSelection()


    var body: some View {
        Section {
            if isEditing {
                MDTextEditor(text: $attributedEditBuffer, selection: $selection)
                .frame(minHeight: 200)
            } else {
                StructuredText(markdown: markdownSource ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
        } header: {
            HStack {
                Text("Description")
                Spacer()
                if isEditing {
                    Button(role: .cancel) {
                        isEditing = false
                        attributedEditBuffer = AttributedString(markdownSource ?? "")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    Spacer()
                        .frame(width: 16)
                    Button {
                        markdownSource = String(attributedEditBuffer.characters)
                        isEditing = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                } else {
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .task {
            attributedEditBuffer = AttributedString(markdownSource ?? "")
        }
    }
}

