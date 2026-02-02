//
//  DeckModels.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

struct DeckBoard: Codable, Identifiable {
    let id: Int
    let title: String
    let archived: Bool
}

struct DeckStack: Codable, Identifiable {
    let id: Int
    let title: String
    let boardId: Int
}

struct DeckCard: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let stackId: Int
    let order: Int
}
