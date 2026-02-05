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
}

@Model
final class Card {
    @Attribute(.unique) var id: Int
    var title: String
    var cardDescription: String?
    var stackId: Int
    var order: Int

    var stack: Stack?
    
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

extension Card {
    convenience init(dto: CardDTO) {

        self.init(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            stackId: dto.stackId,
            order: dto.order
        )
    }

}
