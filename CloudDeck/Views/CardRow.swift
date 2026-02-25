//
//  CardRow.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import SwiftUI

struct CardRow: View {
    let card: Card

    private var hasBottomRow: Bool {
        return !card.assignedUsers.isEmpty ||
        card.dueDate != nil ||
        card.doneAt != nil ||
        card.commentsCount > 0 ||
        card.attachmentCount > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(card.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            if let desc = card.cardDescription,
               !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !card.labels.isEmpty {
                ChipFlowLayout(spacing: 8) {
                    ForEach(card.labels.sorted(by: { $0.title < $1.title } )) { label in
                        ChipView(title: label.title, colorHex: label.color)
                    }
                }
            }

            if hasBottomRow {
                HStack(spacing: 16) {
                    HStack(spacing: 14) {

                        if let dueDate = card.dueDate {
                            if dueDate < Date() {
                                Label {
                                    Text("\(formattedRelativeTime(from: dueDate, relativeTo: Date()))")
                                } icon: {
                                    Image(systemName: "clock")
                                        .symbolVariant(.fill)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.red, .red)
                                }
                                .padding(3)
                                .background(
                                    Capsule().fill(.red.opacity(0.15))
                                )
                            } else {
                                Label {
                                    Text("\(formattedRelativeTime(from: dueDate, relativeTo: Date()))")
                                } icon: {
                                    Image(systemName: "clock")
                                }
                            }
                        } else if let doneAt = card.doneAt {
                            Label {
                                Text("\(formattedRelativeTime(from: doneAt, relativeTo: Date()))")
                            } icon: {
                                Image(systemName: "checkmark")
                                    .symbolVariant(.circle.fill)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .green)
                            }
                            .padding(3)
                            .background(
                                Capsule().fill(.green.opacity(0.15))
                            )
                        }
                        if card.commentsCount > 0 {
                            Label {
                                Text("\(card.commentsCount)")
                            } icon: {
                                Image(systemName: "bubble.left")
                            }
                        }
                        if card.attachmentCount > 0 {
                            Label {
                                Text("\(card.attachmentCount)")
                            } icon: {
                                Image(systemName: "paperclip")
                            }
                        }
                    }

                    Spacer()

                    // Assignees (overlapping)
                    HStack(spacing: -8) {
                        ForEach(card.assignedUsers) { user in
                            AssigneeInitialsView(name: user.user.displayName)
                        }
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    func formattedRelativeTime(from date: Date, relativeTo referenceDate: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full // "1 minute ago" vs "1 min ago"
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }

}

struct AssigneeInitialsView: View {
    let name: String

    var body: some View {
        Text(getInitials(from: name))
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.brown)
            .frame(width: 30, height: 30)
            .background(Circle().fill(Color.brown.opacity(0.3)))
    }

    func getInitials(from name: String) -> String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name) {
            return components.formatted(.name(style: .abbreviated))
        }
        return ""
    }

}
