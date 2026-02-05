//
//  DeckBoard.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import Foundation
import SwiftData

struct BoardDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let owner: UserDTO
    let color: String
    let archived: Bool
    let shared: Int
    let deletedAt: Int
    let lastModified: Int
    let eTag: String
    let permissions: BoardPermissionsDTO

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case owner
        case color
        case archived
        case shared
        case deletedAt
        case lastModified
        case permissions
        case eTag = "ETag"
    }
}

@Model
final class Board {
    @Attribute(.unique) var id: Int

    var title: String
    var colorHex: String
    var archived: Bool

    var ownerUID: String
    var ownerDisplayName: String

    var canRead: Bool
    var canEdit: Bool
    var canManage: Bool
    var canShare: Bool

    var isShared: Bool
    var isDeleted: Bool

    var lastModified: Date?
    var eTag: String?

    init(
        id: Int,
        title: String,
        colorHex: String,
        archived: Bool,
        ownerUID: String,
        ownerDisplayName: String,
        canRead: Bool,
        canEdit: Bool,
        canManage: Bool,
        canShare: Bool,
        isShared: Bool,
        isDeleted: Bool,
        lastModified: Date?,
        eTag: String?
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.archived = archived
        self.ownerUID = ownerUID
        self.ownerDisplayName = ownerDisplayName
        self.canRead = canRead
        self.canEdit = canEdit
        self.canManage = canManage
        self.canShare = canShare
        self.isShared = isShared
        self.isDeleted = isDeleted
        self.lastModified = lastModified
        self.eTag = eTag
    }
}

extension Board {
    convenience init(dto: BoardDTO) {
        self.init(
            id: dto.id,
            title: dto.title,
            colorHex: dto.color,
            archived: dto.archived,
            ownerUID: dto.owner.uid,
            ownerDisplayName: dto.owner.displayname,
            canRead: dto.permissions.canRead,
            canEdit: dto.permissions.canEdit,
            canManage: dto.permissions.canManage,
            canShare: dto.permissions.canShare,
            isShared: dto.shared != 0,
            isDeleted: dto.deletedAt != 0,
            lastModified: Date(timeIntervalSince1970: TimeInterval(dto.lastModified)),
            eTag: dto.eTag
        )
    }

    func update(from dto: BoardDTO) {
        title = dto.title
        colorHex = dto.color
        archived = dto.archived

        ownerUID = dto.owner.uid
        ownerDisplayName = dto.owner.displayname

        canRead = dto.permissions.canRead
        canEdit = dto.permissions.canEdit
        canManage = dto.permissions.canManage
        canShare = dto.permissions.canShare

        isShared = dto.shared != 0
        isDeleted = dto.deletedAt != 0
        lastModified = Date(timeIntervalSince1970: TimeInterval(dto.lastModified))
        eTag = dto.eTag
    }
}
