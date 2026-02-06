//
//  User.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

import SwiftData

struct UserDTO: Codable {
    let primaryKey: String
    let uid: String
    let displayname: String
    let type: Int
}

struct AssignedUserDTO: Codable {
    let id: Int
    let participant: UserDTO
    let cardId: Int
    let type: Int
}

@Model
final class User: Identifiable {
    var primaryKey: String
    var displayName: String
    var type: Int
    var uid: String

    var assignedUser: AssignedUser?
    var card: Card?

    init(primaryKey: String, displayName: String, type: Int, uid: String) {
        self.primaryKey = primaryKey
        self.displayName = displayName
        self.type = type
        self.uid = uid
    }
}

extension User {
    convenience init (dto: UserDTO) {
        self.init(
            primaryKey: dto.primaryKey,
            displayName: dto.displayname,
            type: dto.type,
            uid: dto.uid
        )
    }
}

@Model
final class AssignedUser: Identifiable {
    var id: Int
    var cardId: Int
    var type: Int

    @Relationship(deleteRule: .noAction, inverse: \User.assignedUser)
    var user: User

    var card: Card?

    init(id: Int, cardId: Int, type: Int, user: User) {
        self.id = id
        self.cardId = cardId
        self.type = type
        self.user = user
    }
}

extension AssignedUser {
    convenience init (dto: AssignedUserDTO) {
        self.init(
            id: dto.id,
            cardId: dto.cardId,
            type: dto.type,
            user: .init(dto: dto.participant)
        )
    }
}
