//
//  Label.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/5/26.
//

import Foundation
import SwiftData

struct LabelDTO: Codable {
    let id: Int
    let title: String
    let color: String
    let boardId: Int
    let cardId: Int?
    let lastModified: Int
    let ETag: String
}

@Model
final class DeckLabel {
    @Attribute(.unique) var id: Int
    var title: String
    var color: String
    var boardId: Int
    var cardId: Int?
    var lastModified: Date
    var ETag: String

    var card: Card?

    init(id: Int,
         title: String,
         color: String,
         boardId: Int,
         cardId: Int? = nil,
         lastModified: Date,
         ETag: String) {
        self.id = id
        self.title = title
        self.color = color
        self.boardId = boardId
        self.cardId = cardId
        self.lastModified = lastModified
        self.ETag = ETag
    }

}

extension DeckLabel {

    convenience init(dto: LabelDTO) {
        self.init(id: dto.id,
                  title: dto.title,
                  color: dto.color,
                  boardId: dto.boardId,
                  lastModified: Date(timeIntervalSince1970: TimeInterval(dto.lastModified)),
                  ETag: dto.ETag)
    }
    
}
