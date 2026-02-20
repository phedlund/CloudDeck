//
//  CardContextMenu.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/19/26.
//

import SwiftData
import SwiftUI

struct CardContextMenu: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeckAPI.self) private var deckAPI
    @Environment(AuthenticationManager.self) private var authManager

    @Binding var cardToMove: Card?

    let card: Card

    var body: some View {
        Group {
            Button {
                if let username = authManager.currentAccount()?.username {
                    Task {
                        let backgroundActor = DeckModelActor(modelContainer: modelContext.container)
                        if let stack = await backgroundActor.fetchStack(id: card.stackId) {
                            if let board = await backgroundActor.fetchBoard(id: stack.boardId),
                               let me = board.users.filter(
                                { $0.uid == username }
                               ).first {
                                
                                try? await deckAPI.assignUser(card: card, user: me)
                            }
                        }
                    }
                }
            } label: {
                Label("Assign to me", systemImage: "person")
            }
            //                        .disabled(true)
            Button {
                Task {
                    try? await deckAPI.setCardDone(card: card, done: true)
                }
            } label: {
                Label("Mark as done", systemImage: "checkmark")
            }
            .disabled(card.doneAt != nil)
            Button {
                cardToMove = card
            } label: {
                Label("Move/Copy", systemImage: "square.and.arrow.up.on.square")
            }
            .disabled(false)
            Button {
                Task {
                    try? await deckAPI.setCardArchived(card: card, archived: true)
                }
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .disabled(card.archived)
            Button(role: .destructive) {
                Task {
                    try? await deckAPI.deleteCard(boardId: card.stack?.boardId ?? 0, stackId: card.stack?.id ?? 0, cardId: card.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        
    }
}
