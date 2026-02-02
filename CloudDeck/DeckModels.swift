//
//  DeckModels.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Observation

import SwiftData

@Model
final class DeckBoard {
    @Attribute(.unique) var id: Int
    var title: String
    var archived: Bool

    @Relationship(deleteRule: .cascade)
    var stacks: [DeckStack] = []

    init(id: Int, title: String, archived: Bool) {
        self.id = id
        self.title = title
        self.archived = archived
    }
}

@Model
final class DeckStack {
    @Attribute(.unique) var id: Int
    var title: String
    var boardId: Int

    @Relationship(deleteRule: .cascade)
    var cards: [DeckCard] = []

    init(id: Int, title: String, boardId: Int) {
        self.id = id
        self.title = title
        self.boardId = boardId
    }
}

@Model
final class DeckCard {
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

@Observable
final class DeckModel {
    var boards: [DeckBoard] = []
    var stacks: [DeckStack] = []
    var cards: [DeckCard] = []

    var isSyncing = false

    // MARK: - Boards

    @MainActor
    func refreshBoards() async {
        // TODO: GET /boards
        try? await Task.sleep(for: .seconds(1))
        boards = [
            DeckBoard(id: 1, title: "Personal", archived: false),
            DeckBoard(id: 2, title: "Work", archived: false)
        ]
    }

    // MARK: - Stacks

    @MainActor
    func loadStacks(for board: DeckBoard?) {
        guard let board else {
            stacks = []
            return
        }

        // TODO: GET /boards/{id}/stacks
        stacks = [
            DeckStack(id: 1, title: "To Do", boardId: board.id),
            DeckStack(id: 2, title: "Doing", boardId: board.id),
            DeckStack(id: 3, title: "Done", boardId: board.id)
        ]
    }

    // MARK: - Cards

    @MainActor
    func loadCards(for stack: DeckStack?) {
        guard let stack else {
            cards = []
            return
        }

        // TODO: GET /stacks/{id}/cards
        cards = [
            DeckCard(
                id: 1,
                title: "First card",
                description: "Some details",
                stackId: stack.id,
                order: 1
            ),
            DeckCard(
                id: 2,
                title: "Second card",
                description: nil,
                stackId: stack.id,
                order: 2
            )
        ]
    }

    // MARK: - Sync

    @MainActor
    func sync() async {
        isSyncing = true
        defer { isSyncing = false }

        // TODO: full sync logic
        try? await Task.sleep(for: .seconds(1))
    }
}
