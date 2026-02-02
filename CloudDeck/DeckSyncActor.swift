//
//  DeckSyncActor.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/29/26.
//

import SwiftData

@ModelActor
actor DeckSyncActor {

    func upsertBoards(_ boards: [DeckBoard]) {
        for board in boards {
            let entity = BoardEntity(from: board)
            modelContext.insert(entity)
        }
        try? modelContext.save()
    }
}
