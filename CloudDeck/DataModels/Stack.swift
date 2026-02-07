//
//  DeckStack.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/3/26.
//

import Foundation
import SwiftData

struct StackDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let boardId: Int
    let deletedAt: Int
    let lastModified: Int
    let order: Int
    let eTag: String
    let cards: [CardDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case boardId
        case deletedAt
        case lastModified
        case order
        case cards
        case eTag = "ETag"
    }
}

import SwiftData

@Model
final class Stack {
    @Attribute(.unique) var id: Int
    var title: String
    var boardId: Int
//    var deletedAt: Int
    var order: Int
    var lastModified: Date?
    var isDeleted: Bool

    var eTag: String?

    @Relationship(deleteRule: .cascade, inverse: \Card.stack)
    var cards: [Card]

    init(
        id: Int,
        title: String,
        boardId: Int,
        order: Int,
        lastModified: Date?,
        isDeleted: Bool,
        eTag: String?,
        cards: [Card] = []
    ) {
        self.id = id
        self.title = title
        self.boardId = boardId
        self.order = order
        self.lastModified = lastModified
        self.isDeleted = isDeleted
        self.eTag = eTag
        self.cards = cards
    }
}

extension Stack {
    convenience init(dto: StackDTO) {

        let cardModels = dto.cards.map { Card(dto: $0) }

        self.init(
            id: dto.id,
            title: dto.title,
            boardId: dto.boardId,
            order: dto.order,
            lastModified: Date(timeIntervalSince1970: TimeInterval(dto.lastModified)),
            isDeleted: dto.deletedAt != 0,
            eTag: dto.eTag,
            cards: cardModels
        )
    }

    func update(from dto: StackDTO) {
        title = dto.title
        boardId = dto.boardId
        order = dto.order
        lastModified = Date(timeIntervalSince1970: TimeInterval(dto.lastModified))
        isDeleted = dto.deletedAt != 0
        eTag = dto.eTag
    }
}
