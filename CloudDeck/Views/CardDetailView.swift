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
    @Environment(DeckAPI.self) private var deckAPI

    var body: some View {
        VStack {
            HStack {
                LiveRelativeDateView(targetDate: card.lastModified, style: .modified)
                LiveRelativeDateView(targetDate: card.createdAt, style: .createdAt)
            }
            .padding(.horizontal)
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
                        Toggle("Done", isOn: Binding(
                            get: {
                                card.doneAt != nil
                            },
                            set: { newValue in
                                Task {
                                    do {
                                        try await deckAPI.setCardDone(card: card, done: newValue)
                                    } catch {
                                        // handle error / revert UI if you want
                                    }
                                }
                            }
                        ))
                    } icon: {
                        Image(systemName: "checkmark")
                    }
                }

                Section {
                    TaskDatePicker(date: $card.dueDate)
                } header: {
                    Text("Due date")
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
            .onChange(of: card.dueDate, initial: false) { oldValue, newValue in
                Task {
                    do {
                        try await deckAPI.setCardDueDate(card: card, dueDate: newValue)
                    } catch {
                        // handle error / revert UI if you want
                    }
                }

            }
        }
        .background(.background.secondary)
    }
}

struct LiveRelativeDateView: View {

    enum DateViewStyle {
        case modified
        case createdAt
    }

    var targetDate: Date
    var style: DateViewStyle

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            switch style {
            case .modified:
                Text("Modified \(formattedRelativeTime(from: targetDate, relativeTo: context.date))")
                    .font(.subheadline)
            case .createdAt:
                Text("Created \(formattedRelativeTime(from: targetDate, relativeTo: context.date))")
                    .font(.subheadline)
            }

        }
    }

    // Helper function to format the date
    func formattedRelativeTime(from date: Date, relativeTo referenceDate: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full // "1 minute ago" vs "1 min ago"
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }
}
