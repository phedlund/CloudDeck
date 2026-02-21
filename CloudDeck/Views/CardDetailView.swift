//
//  CardDetailView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(DeckAPI.self) private var deckAPI

    @State private var descriptionUpdateTask: Task<Void, Never>?
    @State private var titleUpdateTask: Task<Void, Never>?

    @State private var showLabels = false
    @State private var pickedLabel: DeckLabel?

    @State private var showUsers = false

    @Query(filter: #Predicate<Board> { !$0.archived }, sort: \.title) private var boards: [Board]

    var boardLabels: [DeckLabel] {
        if let board = boards.first( where: { $0.id == card.stack?.boardId } ) {
            let labels = board.labels
            return labels
        }
        return []
    }

    var boardUsers: [User] {
        if let board = boards.first( where: { $0.id == card.stack?.boardId } ) {
            let users = board.users
            return users
        }
        return []
    }

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
                        ChipFlowView(card.labels) { label in
                            ChipView(
                                title: label.title,
                                colorHex: label.color,
                                onRemove: {
                                    Task {
                                        do {
                                            try await deckAPI.removeCardLabel(card: card, label: label)
                                            // TODO only returns success, need to update db locally
                                        } catch {
                                            // handle error / revert UI if you want
                                        }
                                    }
                                }
                            )
                        } trailing: {
                            Button {
                                showLabels = true
                            } label: {
                                Image(systemName: "plus")
                                    .imageScale(.large)
                            }
                            .buttonStyle(.borderless)
                            .popover(isPresented: $showLabels) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(boardLabels) { label in
                                        Button {
                                            Task {
                                                do {
                                                    try await deckAPI.assignCardLabel(card: card, label: label)
                                                    // TODO only returns success, need to update db locally
                                                } catch {
                                                    // handle error / revert UI if you want
                                                }
                                                showLabels = false
                                            }
                                        } label: {
                                            ChipView(title: label.title, colorHex: label.color)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                                .presentationCompactAdaptation(.popover)
                            }
                        }
                    } icon: {
                        Image(systemName: "tag")
                    }
                    Label {
                        ChipFlowView(card.assignedUsers) { user in
                            ChipView(
                                title: user.user.displayName,
                                colorHex: Color.secondary.opacity(0.3).hexString,
                                onRemove: {
                                    Task {
                                        do {
                                            try await deckAPI.unassignUser(card: card, user: user.user)
                                            // TODO only returns success, need to update db locally
                                        } catch {
                                            // handle error / revert UI if you want
                                        }
                                    }
                                }
                            )
                        } trailing: {
                            Button {
                                showUsers = true
                            } label: {
                                Image(systemName: "plus")
                                    .imageScale(.large)
                            }
                            .buttonStyle(.borderless)
                            .popover(isPresented: $showUsers) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(boardUsers) { user in
                                        Button {
                                            Task {
                                                do {
                                                    try await deckAPI.assignUser(card: card, user: user)
                                                    // TODO only returns success, need to update db locally
                                                } catch {
                                                    // handle error / revert UI if you want
                                                }
                                                showUsers = false
                                            }
                                        } label: {
                                            ChipView(title: user.displayName, colorHex: Color.secondary.opacity(0.3).hexString)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                                .presentationCompactAdaptation(.popover)
                            }
                        }
                    } icon: {
                        Image(systemName: "person")
                    }
                    TaskDatePicker(date: $card.dueDate)
                    Label {
                        Toggle("", isOn: Binding(
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
