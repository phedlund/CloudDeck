//
//  DeckDTOs.swift
//  CloudDeck
//
//  Created by Assistant on 2/1/26.
//

import Foundation

// Represents a Deck board returned from the API
struct DeckBoardDTO: Decodable, Identifiable, Equatable {
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

// Represents a stack (column) within a board
struct DeckStackDTO: Decodable, Identifiable, Equatable {
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

// Represents a card within a stack
struct DeckCardDTO: Decodable, Identifiable, Equatable {
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
