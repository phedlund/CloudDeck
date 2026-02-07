//
//  CardDetailView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import SwiftUI

struct CardDetailView: View {
    @Bindable var card: Card
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Description") {
                TextEditor(text: Binding(
                    get: { card.cardDescription ?? "" },
                    set: { card.cardDescription = $0 }
                ))
                .frame(minHeight: 120)
            }

            Section {
                Label {
                    Toggle("", isOn: $card.done)
                } icon: {
                    Image(systemName: "checkmark")
                }
            }

            Section {
                TaskDatePicker(date: $card.duedate)
            }

            if !$card.labels.isEmpty {
                Section {
                    Label {
                        TagFlowView(tags: card.labels)
                    } icon: {
                        Image(systemName: "tag")
                    }
                }
            }
            if !$card.assignedUsers.isEmpty {
                Section("Assigned Users") {
                    ForEach(card.assignedUsers) {
                        Label($0.user.displayName, systemImage: "person")
                    }
                }
            }

            Section("Owner") {
                Label(card.owner.displayName, systemImage: "person")
            }

        }
        .navigationTitle($card.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .confirm) {
                    dismiss()
                }
            }
        }

    }
}
