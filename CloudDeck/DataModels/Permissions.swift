//
//  Permissions.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

struct BoardPermissionsDTO: Codable {
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
