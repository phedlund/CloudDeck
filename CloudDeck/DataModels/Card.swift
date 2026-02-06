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
    let order: Int
    let archived: Bool
    let deletedAt: Int
    let lastModified: Int
    let labels: [LabelDTO]
    let done: Bool?
    let duedate: String?
    let owner: UserDTO
    let assignedUsers: [AssignedUserDTO]
}

@Model
final class Card {
    @Attribute(.unique) var id: Int
    var title: String
    var cardDescription: String?
    var stackId: Int
    var order: Int
    var done: Bool
    var duedate: Date?

    var stack: Stack?

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
        order: Int,
        labels: [DeckLabel] = [],
        done: Bool? = nil,
        duedate: Date? = nil,
        owner: User,
        assignedUsers: [AssignedUser] = []
    ) {
        self.id = id
        self.title = title
        self.cardDescription = description
        self.stackId = stackId
        self.order = order
        self.labels = labels
        self.done = done ?? false
        self.duedate = duedate
        self.owner = owner
        self.assignedUsers = assignedUsers
    }
}

extension Card {
    convenience init(dto: CardDTO) {

        let labelModels = dto.labels.map { DeckLabel(dto: $0) }
        var cardDueDate: Date?
        if dto.duedate != nil {
            let formatter = ISO8601DateFormatter()
            cardDueDate = formatter.date(from: dto.duedate!)
        }
        let assignedUsers = dto.assignedUsers.map { AssignedUser(dto: $0) }

        self.init(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            stackId: dto.stackId,
            order: dto.order,
            labels: labelModels,
            done: dto.done,
            duedate: cardDueDate,
            owner: .init(dto: dto.owner),
            assignedUsers: assignedUsers
        )
    }

}
