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
            Section {
                TextField("Title", text: $card.title)
                    .font(.headline)
            }

            Section("Description") {
                TextEditor(text: Binding(
                    get: { card.cardDescription ?? "" },
                    set: { card.cardDescription = $0 }
                ))
                .frame(minHeight: 120)
            }

            Section("Status") {
                Toggle(.cardDoneToggle, isOn: $card.done)
            }

            //                Section("Assignment") {
            //                    if let assignee = card. {
            //                        Text(assignee)
            //                    } else {
            //                        Text(.unassigned)
            //                            .foregroundStyle(.secondary)
            //                    }
            //                }

            Section("Due Date") {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { card.duedate ?? Date() },
                        set: { card.duedate = $0 }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
            }

            if !$card.labels.isEmpty {
                Section("Tags") {
                    TagFlowView(tags: card.labels)
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
        .navigationTitle(card.title)
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
