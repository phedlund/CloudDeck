//
//  Permissions.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

import Foundation
import SwiftData

struct PermissionsDTO: Codable {
    let canRead: Bool
    let canEdit: Bool
    let canManage: Bool
    let canShare: Bool

    enum CodingKeys: String, CodingKey {
        case canRead = "PERMISSION_READ"
        case canEdit = "PERMISSION_EDIT"
        case canManage = "PERMISSION_MANAGE"
        case canShare = "PERMISSION_SHARE"
    }
}

@Model
final class Permissions {
    var canRead: Bool
    var canEdit: Bool
    var canManage: Bool
    var canShare: Bool

    @Relationship(inverse: \Board.permissions) var board: Board?

    init(canRead: Bool, canEdit: Bool, canManage: Bool, canShare: Bool) {
        self.canRead = canRead
        self.canEdit = canEdit
        self.canManage = canManage
        self.canShare = canShare
    }

    convenience init(dto: PermissionsDTO) {
        self.init(
            canRead: dto.canRead,
            canEdit: dto.canEdit,
            canManage: dto.canManage,
            canShare: dto.canShare
        )
    }

}

struct ACLItemDTO: Decodable {
    let uid: String
    let permission: String
}

@Model
final class ACLItem {
    var uid: String
    var permission: String

    init(uid: String, permission: String) {
        self.uid = uid
        self.permission = permission
    }

    convenience init(dto: ACLItemDTO) {
        self.init(
            uid: dto.uid,
            permission: dto.permission
        )
    }
}

struct ActiveSessionDTO: Decodable {
    let userId: String
    let lastSeen: Date
}

@Model
final class ActiveSession {
    var userId: String
    var lastSeen: Date

    init(userId: String, lastSeen: Date) {
        self.userId = userId
        self.lastSeen = lastSeen
    }

    convenience init(dto: ActiveSessionDTO) {
        self.init(
            userId: dto.userId,
            lastSeen: dto.lastSeen
        )
    }
}

@Model
final class BoardSettings {
    var notifyDue: String?
    var calendar: Bool?

    init(notifyDue: String? = nil, calendar: Bool? = nil) {
        self.notifyDue = notifyDue
        self.calendar = calendar
    }
}
