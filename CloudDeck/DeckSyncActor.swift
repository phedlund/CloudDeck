//
//  DeckSyncActor.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/29/26.
//

import SwiftData
import Foundation

@ModelActor
actor DeckSyncActor {

    private var modelContext: ModelContext { modelExecutor.modelContext }

    // MARK: - Boards

    func syncBoards() async throws {
//        let remoteBoards = try await DeckAPI.fetchBoards()
//
//        for board in remoteBoards {
//            upsert(board)
//        }
//
//        try modelContext.save()
    }

    // MARK: - Stacks

    func syncStacks(boardId: Int) async throws {
        let remoteStacks = try await DeckAPI.fetchStacks(boardId: boardId)

        for stack in remoteStacks {
            upsert(stack)
        }

        try modelContext.save()
    }

    // MARK: - Cards

    func syncCards(stackId: Int) async throws {
        let remoteCards = try await DeckAPI.fetchCards(stackId: stackId)

        for card in remoteCards {
            upsert(card)
        }

        try modelContext.save()
    }
}

extension DeckSyncActor {

    private func upsert(_ dto: DeckBoardDTO) {
        if let existing = fetchBoard(id: dto.id) {
            existing.title = dto.title
            existing.archived = dto.archived ?? false
        } else {
            modelContext.insert(
                DeckBoard(
                    id: dto.id,
                    title: dto.title,
                    archived: dto.archived ?? false
                )
            )
        }
    }

    private func upsert(_ dto: DeckStackDTO) {
        if let existing = fetchStack(id: dto.id) {
            existing.title = dto.title
            existing.boardId = dto.boardId
        } else {
            modelContext.insert(
                DeckStack(
                    id: dto.id,
                    title: dto.title,
                    boardId: dto.boardId
                )
            )
        }
    }

    private func upsert(_ dto: DeckCardDTO) {
        if let existing = fetchCard(id: dto.id) {
            existing.title = dto.title
            existing.cardDescription = dto.description
            existing.stackId = dto.stackId
            existing.order = dto.order ?? 0
        } else {
            modelContext.insert(
                DeckCard(
                    id: dto.id,
                    title: dto.title,
                    description: dto.description,
                    stackId: dto.stackId,
                    order: dto.order ?? 0
                )
            )
        }
    }
}
extension DeckSyncActor {

    // MARK: - Fetch helpers

    private func fetchBoard(id: Int) -> DeckBoard? {
        let descriptor = FetchDescriptor<DeckBoard>(
            predicate: #Predicate { $0.id == id },
            sortBy: []
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchStack(id: Int) -> DeckStack? {
        let descriptor = FetchDescriptor<DeckStack>(
            predicate: #Predicate { $0.id == id },
            sortBy: []
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchCard(id: Int) -> DeckCard? {
        let descriptor = FetchDescriptor<DeckCard>(
            predicate: #Predicate { $0.id == id },
            sortBy: []
        )
        return try? modelContext.fetch(descriptor).first
    }
}

