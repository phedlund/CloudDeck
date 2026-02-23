//
//  DeckCard.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import Foundation
import SwiftData
import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    static let cloudDeckCard = UTType(exportedAs: "dev.pbh.clouddeckcard")
    static let cloudDeckStack = UTType(exportedAs: "dev.pbh.clouddeckstack")
}

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

    @EpochDateOrNil var lastModified: Date?
    @EpochDateOrNil var createdAt: Date?
    @EpochDateOrNil var deletedAt: Date?

    @ISO8601DateOrNil var done: Date?
    @ISO8601DateOrNil var duedate: Date?
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
    var createdAt: Date?
    var lastModified: Date?
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
        createdAt: Date?,
        lastModified: Date?,
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
            createdAt: dto.createdAt,
            lastModified: dto.lastModified,
            doneAt: dto.done,
            dueDate: dto.duedate,
            deletedAt: dto.deletedAt,
            owner: .init(dto: dto.owner),
            assignedUsers: assignedUsers
        )
    }

}

struct CardDragItem: Codable, Transferable, Sendable {
    let cardID: Int

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .cloudDeckCard)
    }
}

struct StackDragItem: Codable, Transferable, Sendable {
    let stackID: Int
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .cloudDeckStack)
    }
}
