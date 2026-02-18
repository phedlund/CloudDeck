//
//  DeckCard.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import Foundation
import SwiftData

struct CardDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let stackId: Int
    let type: String
    let order: Int
    let archived: Bool
    let labels: [LabelDTO]
    let owner: UserDTO
    let assignedUsers: [AssignedUserDTO]

    let lastModified: Int
    let createdAt: Int
    let deletedAt: Int

    let done: String?
    let duedate: String?
}

extension CardDTO {

    var createdDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt))
    }

    var modifiedDate: Date {
        Date(timeIntervalSince1970: TimeInterval(lastModified))
    }

    func parsedDone(using iso: ISO8601DateFormatter) -> Date? {
        done.flatMap { iso.date(from: $0) }
    }

    func parsedDue(using iso: ISO8601DateFormatter) -> Date? {
        duedate.flatMap { iso.date(from: $0) }
    }
}

@Model
final class Card {
    @Attribute(.unique) var id: Int
    var title: String
    var cardDescription: String?
    var stackId: Int
    var type: String
    var order: Int
    var archived: Bool
    var createdAt: Date
    var lastModified: Date
    var dueDate: Date?
    var doneAt: Date?
    var deletedAt: Date?

    @Relationship(inverse: \Stack.cards) var stack: Stack?

    @Relationship(deleteRule: .noAction, inverse: \DeckLabel.card)
    var labels: [DeckLabel]
    @Relationship(deleteRule: .noAction, inverse: \User.card)
    var owner: User
    @Relationship(deleteRule: .noAction, inverse: \AssignedUser.card)
    var assignedUsers: [AssignedUser]


    init(
        id: Int,
        title: String,
        description: String?,
        stackId: Int,
        type: String,
        order: Int,
        archived: Bool,
        labels: [DeckLabel] = [],
        createdAt: Date,
        lastModified: Date,
        doneAt: Date? = nil,
        dueDate: Date? = nil,
        deletedAt: Date? = nil,
        owner: User,
        assignedUsers: [AssignedUser] = []
    ) {
        self.id = id
        self.title = title
        self.cardDescription = description
        self.stackId = stackId
        self.type = type
        self.order = order
        self.archived = archived
        self.labels = labels
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.doneAt = doneAt
        self.dueDate = dueDate
        self.deletedAt = deletedAt
        self.owner = owner
        self.assignedUsers = assignedUsers
    }
}

extension Card {
    convenience init(dto: CardDTO) {
        let iso = ISO8601DateFormatter()

        let labelModels = dto.labels.map { DeckLabel(dto: $0) }
        let assignedUsers = dto.assignedUsers.map { AssignedUser(dto: $0) }

        self.init(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            stackId: dto.stackId,
            type: dto.type,
            order: dto.order,
            archived: dto.archived,
            labels: labelModels,
            createdAt: Date(timeIntervalSince1970: TimeInterval(dto.createdAt)),
            lastModified: Date(timeIntervalSince1970: TimeInterval(dto.lastModified)),
            doneAt: dto.done.flatMap { iso.date(from: $0) },
            dueDate: dto.duedate.flatMap { iso.date(from: $0) },
            deletedAt: dto.deletedAt == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(dto.deletedAt)),
            owner: .init(dto: dto.owner),
            assignedUsers: assignedUsers
        )
    }

}
