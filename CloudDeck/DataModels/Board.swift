//
//  DeckBoard.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import Foundation
import SwiftData

// Summary DTO — returned by GET /boards
struct BoardSummaryDTO: Decodable {
    let id: Int
    let title: String
    let color: String
    let archived: Bool
    let deletedAt: Int
    let lastModified: Int
    let eTag: String
    let owner: UserDTO
    let users: [UserDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case owner
        case color
        case archived
        case deletedAt
        case lastModified
        case users
        case eTag = "ETag"
    }
}

// Detail DTO — returned by GET /boards/{id}
struct BoardDetailDTO: Decodable {
    let id: Int
    let title: String
    let color: String
    let archived: Bool
    let deletedAt: Int
    let lastModified: Int
    let eTag: String
    let owner: UserDTO
    let users: [UserDTO]
    let stacks: [StackDTO]
    let labels: [LabelDTO]
    let permissions: PermissionsDTO
    let acl: [ACLItemDTO]
    let activeSessions: [ActiveSessionDTO]
    let settings: [String: CodableValue] // e.g., ["notify-due": "assigned"]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case color
        case archived
        case deletedAt
        case lastModified
        case owner
        case users
        case stacks
        case labels
        case permissions
        case acl
        case activeSessions
        case settings
        case eTag = "ETag"
    }
}

enum CodableValue: Codable {
    case bool(Bool)
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) { self = .bool(b) }
        else if let i = try? container.decode(Int.self) { self = .int(i) }
        else if let s = try? container.decode(String.self) { self = .string(s) }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown setting type") }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let b): try container.encode(b)
        case .int(let i): try container.encode(i)
        case .string(let s): try container.encode(s)
        }
    }
}

@Model
final class Board {
    @Attribute(.unique) var id: Int
    var title: String
    var color: String
    var archived: Bool
    var deletedAt: Int
    var lastModified: Date
    var eTag: String

    // Relationships
    @Relationship(deleteRule: .nullify)
    var owner: User?

    @Relationship(deleteRule: .nullify)
    var users: [User] = []

    @Relationship(deleteRule: .cascade) var stacks: [Stack] = []

    @Relationship(deleteRule: .cascade)
    var labels: [DeckLabel] = []

    @Relationship(deleteRule: .cascade)
    var acl: [ACLItem] = []

    @Relationship(deleteRule: .cascade)
    var activeSessions: [ActiveSession] = []

    var permissions: Permissions?
    var settings: BoardSettings?

    var isFullyHydrated: Bool {
        !stacks.isEmpty && permissions != nil
    }

    init(id: Int,
         title: String,
         color: String,
         archived: Bool = false,
         deletedAt: Int = 0,
         lastModified: Date = Date(),
         eTag: String = "",
         owner: User,
         users: [User] = []) {
        self.id = id
        self.title = title
        self.color = color
        self.archived = archived
        self.deletedAt = deletedAt
        self.lastModified = lastModified
        self.eTag = eTag
        self.owner = owner
        self.users = users
    }
}

extension Board {
    convenience init(dto: BoardSummaryDTO) {

        let userModels = dto.users.map { User(dto: $0) }

        self.init(
            id: dto.id,
            title: dto.title,
            color: dto.color,
            archived: dto.archived,
            deletedAt: dto.deletedAt,
            lastModified: Date(timeIntervalSince1970: TimeInterval(dto.lastModified)),
            eTag: dto.eTag,
            owner: .init(dto: dto.owner),
            users: userModels
        )
    }

    convenience init(dto: BoardDetailDTO) {

        let userModels = dto.users.map { User(dto: $0) }

        self.init(
            id: dto.id,
            title: dto.title,
            color: dto.color,
            archived: dto.archived,
            deletedAt: dto.deletedAt,
            lastModified: Date(timeIntervalSince1970: TimeInterval(dto.lastModified)),
            eTag: dto.eTag,
            owner: .init(dto: dto.owner),
            users: userModels
        )
    }

}

extension Board {
    func applySummary(from dto: BoardSummaryDTO) {
        title = dto.title
        color = dto.color
        archived = dto.archived
        deletedAt = dto.deletedAt
        lastModified = Date(timeIntervalSince1970: TimeInterval(dto.lastModified))
        eTag = dto.eTag
    }

    func applyDetail(from dto: BoardDetailDTO) {

        let stackModels = dto.stacks.map { Stack(dto: $0) }
        let labelModels = dto.labels.map { DeckLabel(dto: $0) }

        title = dto.title
        color = dto.color
        archived = dto.archived
        deletedAt = dto.deletedAt
        lastModified = Date(timeIntervalSince1970: TimeInterval(dto.lastModified))
        eTag = dto.eTag
        stacks = stackModels
        labels = labelModels
        permissions = Permissions(canRead: dto.permissions.canRead,
                                  canEdit: dto.permissions.canEdit,
                                  canManage: dto.permissions.canManage,
                                  canShare: dto.permissions.canShare)
        users = dto.users.map(User.init)
//        activeSessions = dto.activeSessions.map(ActiveSession.init)
//        settings = BoardSettings(notifyDue: dto.settings["notify-due"],
//                                 calendar: dto.settings["calendar"])
        acl = dto.acl.map { ACLItem(uid: $0.uid, permission: $0.permission) }
    }
}
