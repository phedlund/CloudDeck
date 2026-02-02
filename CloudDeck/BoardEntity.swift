//
//  BoardEntity.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/29/26.
//

import SwiftData

@Model
final class BoardEntity {
    @Attribute(.unique) var id: Int
    var title: String
    var archived: Bool

    init(from board: DeckBoard) {
        self.id = board.id
        self.title = board.title
        self.archived = board.archived
    }
}
