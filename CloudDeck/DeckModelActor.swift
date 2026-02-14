//
//  DeckSyncActor.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/29/26.
//

import SwiftData
import Foundation

public let schema = Schema([
    Board.self,
    Stack.self,
    Card.self,
    DeckLabel.self,
    User.self,
    AssignedUser.self,
    Permissions.self,
    ACLItem.self,
    ActiveSession.self,
    BoardSettings.self
])

@ModelActor
actor DeckModelActor: Sendable {

    private var modelContext: ModelContext { modelExecutor.modelContext }

    func save() async throws {
        try modelContext.save()
    }

}

extension DeckModelActor {

    func insert(_ dto: BoardSummaryDTO) {
        modelContext.insert(
            Board(dto: dto)
        )
    }

    func insert(_ dto: BoardDetailDTO) {
        let board = fetchBoard(id: dto.id)
        board?.applyDetail(from: dto)
    }

    func deleteBoard(boardId: Int) {
        if let board = fetchBoard(id: boardId) {
            modelContext.delete(board)
            try? modelContext.save()
        }
    }

    func apply(stackDTOs: [StackDTO], boardID: Int) throws {

        var serverStackIDs = Set<Int>()

        for stackDTO in stackDTOs {
            serverStackIDs.insert(stackDTO.id)
            modelContext.insert(Stack(dto: stackDTO))

            try reconcileCards(stackID: stackDTO.id, cardDTOs: stackDTO.cards ?? [])
        }

        try deleteMissingStacks(boardID: boardID, keep: serverStackIDs)
        try modelContext.save()
    }

    func addStack(_ dto: StackDTO) throws {
        modelContext.insert(Stack(dto: dto))
        try modelContext.save()
    }

    func deleteStack(stackId: Int) {
        if let stack = fetchStack(id: stackId) {
            modelContext.delete(stack)
            try? modelContext.save()
        }
    }

    private func reconcileCards(stackID: Int, cardDTOs: [CardDTO]) throws {

        var serverIDs = Set<Int>()

        for dto in cardDTOs {

            serverIDs.insert(dto.id)
            if dto.deletedAt != 0 {
                try deleteCardIfExists(dto.id)
                continue
            }
        }

        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.stackId == stackID }
        )

        let locals = try modelContext.fetch(descriptor)

        for local in locals where !serverIDs.contains(local.id) {
            modelContext.delete(local)
        }
    }

    private func deleteMissingStacks(boardID: Int, keep serverIDs: Set<Int>) throws {

        let descriptor = FetchDescriptor<Stack>(
            predicate: #Predicate { $0.boardId == boardID }
        )

        let locals = try modelContext.fetch(descriptor)

        for stack in locals where !serverIDs.contains(stack.id) {
            modelContext.delete(stack)
        }
    }

    private func deleteCardIfExists(_ id: Int) throws {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        }
    }

    func insertNewCard(from dto: CardDTO) throws {

        // fetch stack first (must exist — we created card inside it)
        guard let stack = fetchStack(id: dto.stackId) else {
            return
//            throw DeckSyncError.missingStack(dto.stackId)
        }

//        let labelModels = dto.labels.map { DeckLabel(dto: $0) }

        let card = Card(dto: dto)

        // relationship — SwiftData manages inverse automatically
        card.stack = stack
        modelContext.insert(card)
        try modelContext.save()
    }
}

extension DeckModelActor {

    // MARK: - Fetch helpers

    private func fetchBoard(id: Int) -> Board? {
        let descriptor = FetchDescriptor<Board>(
            predicate: #Predicate { $0.id == id },
            sortBy: []
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchStack(id: Int) -> Stack? {
        let descriptor = FetchDescriptor<Stack>(
            predicate: #Predicate { $0.id == id },
            sortBy: []
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchCard(id: Int) -> Card? {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == id },
            sortBy: []
        )
        return try? modelContext.fetch(descriptor).first
    }
}

