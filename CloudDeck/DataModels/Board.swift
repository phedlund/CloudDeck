//
//  DeckBoard.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import SwiftData

struct BoardDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String
    let color: String?
    let archived: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case color
        case archived
    }
}

@Model
final class Board {
    @Attribute(.unique) var id: Int
    var title: String
    var archived: Bool

    @Relationship(deleteRule: .cascade)
    var stacks: [Stack] = []

    init(id: Int, title: String, archived: Bool) {
        self.id = id
        self.title = title
        self.archived = archived
    }
}
