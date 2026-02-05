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
        modelContext.insert(
            Board(dto: dto)
        )
    }

    func upsert(_ dto: StackDTO) {
        modelContext.insert(
            Stack(dto: dto)
        )
    }

    private func upsert(_ dto: CardDTO) {
        if let existing = fetchCard(id: dto.id) {
            existing.title = dto.title
            existing.cardDescription = dto.description
            existing.stackId = dto.stackId
            existing.order = dto.order
        } else {
            modelContext.insert(
                Card(
                    id: dto.id,
                    title: dto.title,
                    description: dto.description,
                    stackId: dto.stackId,
                    order: dto.order
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

