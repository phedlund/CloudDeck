//
//  ACL.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 3/2/26.
//

import Foundation
import SwiftData

/*
    {
      "id": 1,
      "participant": {
        "primaryKey": "Peter iCloud",
        "uid": "Peter iCloud",
        "displayname": "Peter iCloud",
        "type": 0
      },
      "type": 0,
      "boardId": 3,
      "permissionEdit": true,
      "permissionShare": false,
      "permissionManage": false,
      "owner": false
    }
*/

struct ACLItemDTO: Decodable, Identifiable {
    let id: Int
    let participant: UserDTO
    let type: Int
    let boardId: Int
    let permissionEdit: Bool
    let permissionShare: Bool
    let permissionManage: Bool
    let owner: Bool
}

@Model
final class ACLItem {
    var id: Int
    var participant: User
    var type: Int
    var boardId: Int
    var permissionEdit: Bool
    var permissionShare: Bool
    var permissionManage: Bool
    var owner: Bool

    init(id: Int, participant: User, type: Int, boardId: Int, permissionEdit: Bool, permissionShare: Bool, permissionManage: Bool, owner: Bool) {
        self.id = id
        self.participant = participant
        self.type = type
        self.boardId = boardId
        self.permissionEdit = permissionEdit
        self.permissionShare = permissionShare
        self.permissionManage = permissionManage
        self.owner = owner
    }

    convenience init(dto: ACLItemDTO) {

        self.init(id: dto.id,
                  participant: .init(dto: dto.participant),
                  type: dto.type,
                  boardId: dto.boardId,
                  permissionEdit: dto.permissionEdit,
                  permissionShare: dto.permissionShare,
                  permissionManage: dto.permissionManage,
                  owner: dto.owner)
    }
}
