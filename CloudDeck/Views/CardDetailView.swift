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

    @State private var descriptionUpdateTask: Task<Void, Never>?
    @State private var titleUpdateTask: Task<Void, Never>?

    var body: some View {
        VStack {
            HStack {
                LiveRelativeDateView(targetDate: card.lastModified, style: .modified)
                LiveRelativeDateView(targetDate: card.createdAt, style: .createdAt)
            }
            .padding(.horizontal)
            Form {
                Section("Description") {
                    TextEditor(text: $card.cardDescription.emptyString)
                        .onChange(of: card.cardDescription) {
                            scheduleDescriptionUpdate()
                        }
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
                            ChipFlowView(card.labels) { label in
                                ChipView(
                                    title: label.title,
                                    colorHex: label.color,
                                    onRemove: {
//                                        removeTag(tag)
                                    }
                                )
                            }
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
            .onChange(of: card.title, initial: false) { _, newValue in
                scheduleTitleUpdate()
            }
        }
        .background(.background.secondary)
    }

    private func scheduleDescriptionUpdate() {
        descriptionUpdateTask?.cancel()

        descriptionUpdateTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }

            try? await deckAPI.updateCard(card)
        }
    }

    private func scheduleTitleUpdate() {
        titleUpdateTask?.cancel()

        titleUpdateTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }

            try? await deckAPI.updateCard(card)
        }
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

extension Binding where Value == String? {
    var emptyString: Binding<String> {
        Binding<String>(
            get: { wrappedValue ?? "" },
            set: { wrappedValue = $0 }   // ← keep empty string, don’t turn into nil
        )
    }
}
