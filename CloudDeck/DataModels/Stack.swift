//
//  DeckStack.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import SwiftData

struct StackDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String
    let order: Int?
    let boardId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case order
        case boardId = "board_id"
    }
}

@Model
final class Stack {
    @Attribute(.unique) var id: Int
    var title: String
    var boardId: Int

    @Relationship(deleteRule: .cascade)
    var cards: [Card] = []

    init(id: Int, title: String, boardId: Int) {
        self.id = id
        self.title = title
        self.boardId = boardId
    }
}
