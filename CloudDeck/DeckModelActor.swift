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
    Card.self
])

@ModelActor
actor DeckModelActor: Sendable {

    private var modelContext: ModelContext { modelExecutor.modelContext }

    func save() async throws {
        try modelContext.save()
    }

}

extension DeckModelActor {

    func upsert(_ dto: BoardDTO) {
        if let existing = fetchBoard(id: dto.id) {
            existing.title = dto.title
            existing.archived = dto.archived ?? false
        } else {
            modelContext.insert(
                Board(
                    id: dto.id,
                    title: dto.title,
                    archived: dto.archived ?? false
                )
            )
        }
    }

    private func upsert(_ dto: StackDTO) {
        if let existing = fetchStack(id: dto.id) {
            existing.title = dto.title
            existing.boardId = dto.boardId
        } else {
            modelContext.insert(
                Stack(
                    id: dto.id,
                    title: dto.title,
                    boardId: dto.boardId
                )
            )
        }
    }

    private func upsert(_ dto: CardDTO) {
        if let existing = fetchCard(id: dto.id) {
            existing.title = dto.title
            existing.cardDescription = dto.description
            existing.stackId = dto.stackId
            existing.order = dto.order ?? 0
        } else {
            modelContext.insert(
                Card(
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

