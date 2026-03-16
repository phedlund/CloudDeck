//
//  CardDescriptionSection.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 3/10/26.
//

import SwiftUI
import Textual

struct CardDescriptionSection: View {
    @Binding var markdownSource: String?
    @State private var isEditing = false
    @State private var editBuffer: String = ""
    @State private var originalMarkdown: String?

    var body: some View {
        Section {
            if isEditing {
                TextEditor(text: $editBuffer)
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
                        editBuffer = originalMarkdown ?? ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    Spacer()
                        .frame(width: 16)
                    Button {
                        markdownSource = editBuffer
                        isEditing = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                } else {
                    Button {
                        editBuffer = markdownSource ?? ""
                        originalMarkdown = markdownSource
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
    }
}

