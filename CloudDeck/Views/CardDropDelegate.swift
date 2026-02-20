//
//  CardDropDelegate.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/19/26.
//

import SwiftData
import SwiftUI

struct CardDropDelegate: DropDelegate {
    let destinationCard: Card
    let allCards: [Card] // The current sorted state from @Query
    @Binding var draggedCard: Card?

    func dropEntered(info: DropInfo) {
        guard let draggedCard = draggedCard, 
              draggedCard != destinationCard else { return }

        // 2. Perform the reorder logic on a local copy of the array
        var revisedCards = allCards
        if let fromIndex = revisedCards.firstIndex(of: draggedCard),
           let toIndex = revisedCards.firstIndex(of: destinationCard) {
            
            withAnimation(.spring()) {
                revisedCards.move(fromOffsets: IndexSet(integer: fromIndex),
                                 toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                
                // 3. Batch update the 'order' property on the actual SwiftData models
                for (index, card) in revisedCards.enumerated() {
                    card.order = index
                }
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedCard = nil
        return true
    }
}
