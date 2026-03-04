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
    let attachmentCount: Int
    let commentsCount: Int
    let overdue: Int

    @EpochDateOrNil var lastModified: Date?
    @EpochDateOrNil var createdAt: Date?
    @EpochDateOrNil var deletedAt: Date?

    @ISO8601DateOrNil var done: Date?
    @ISO8601DateOrNil var duedate: Date?
}

struct NewCardDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let descriptionPrev: String?
    let stackId: Int
    let type: String
    let lastModified: Int
    let lastEditor: String?
    let createdAt: Int
    let labels: [LabelDTO]
    let assignedUsers: [AssignedUserDTO]?
//    let attachments: [AttachmentDTO]?
    let attachmentCount: Int?
    let owner: UserDTO
    let order: Int
    let archived: Bool
    @ISO8601DateOrNil var done: Date?
    @ISO8601DateOrNil var duedate: Date?
    let notified: Bool
    let deletedAt: Int
    let commentsUnread: Int
    let commentsCount: Int
    let relatedStack: StackDTO?
    let relatedBoard: BoardSummaryDTO?
    let eTag: String

    enum CodingKeys: String, CodingKey {
        case id, title, description, descriptionPrev, stackId, type
        case lastModified, lastEditor, createdAt, labels, assignedUsers
        case attachmentCount, owner, order, archived, done
        case duedate, notified, deletedAt, commentsUnread, commentsCount
        case relatedStack, relatedBoard
        case eTag = "ETag"
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
    var createdAt: Date?
    var lastModified: Date?
    var dueDate: Date?
    var doneAt: Date?
    var deletedAt: Date?
    var attachmentCount: Int
    var commentsCount: Int
    var overdue: Int


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
        assignedUsers: [AssignedUser] = [],
        attachmentCount: Int,
        commentsCount: Int,
        overdue: Int
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
        self.attachmentCount = attachmentCount
        self.commentsCount = commentsCount
        self.overdue = overdue
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
            assignedUsers: assignedUsers,
            attachmentCount: dto.attachmentCount,
            commentsCount: dto.commentsCount,
            overdue: dto.overdue
        )
    }

    convenience init(dto: NewCardDTO) {

        let labelModels = dto.labels.map { DeckLabel(dto: $0) }
        var assignedUsers: [AssignedUser]? = nil
        if let dtoAssignedUsers = dto.assignedUsers {
            assignedUsers = dtoAssignedUsers.map { AssignedUser(dto: $0) }
        }

        self.init(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            stackId: dto.stackId,
            type: dto.type,
            order: dto.order,
            archived: dto.archived,
            labels: labelModels,
            createdAt: dto.createdAt == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(dto.createdAt)),
            lastModified: dto.lastModified == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(dto.lastModified)),
            doneAt: dto.done,
            dueDate: dto.duedate,
            deletedAt: dto.deletedAt == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(dto.deletedAt)),
            owner: .init(dto: dto.owner),
            assignedUsers: assignedUsers ?? [],
            attachmentCount: dto.attachmentCount ?? 0,
            commentsCount: dto.commentsCount,
            overdue: 0
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
