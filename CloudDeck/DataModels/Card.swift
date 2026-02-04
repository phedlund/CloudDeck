//
//  DeckCard.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import Foundation
import SwiftData

struct CardDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String?
    let stackId: Int
    let order: Int?
    let archived: Bool?
    let dueDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case stackId = "stack_id"
        case order
        case archived
        case dueDate = "duedate"
    }
}

@Model
final class Card {
    @Attribute(.unique) var id: Int
    var title: String
    var cardDescription: String?
    var stackId: Int
    var order: Int

    init(
        id: Int,
        title: String,
        description: String?,
        stackId: Int,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.cardDescription = description
        self.stackId = stackId
        self.order = order
    }
}
