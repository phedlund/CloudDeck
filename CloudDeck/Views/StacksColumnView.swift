//
//  StacksColumnView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/4/26.
//

import SwiftUI
import SwiftData

struct StacksColumnView: View {
    let boardID: Int?
    @Binding var selectedStackID: Int?

    @Query private var boards: [Board]
    @Query private var stacks: [Stack]
    @Query private var cards: [Card]

    @State private var showNewStackSheet: Bool = false

    init(boardID: Int?, selectedStackID: Binding<Int?>) {
        self.boardID = boardID
        self._selectedStackID = selectedStackID

        if let boardID {
            _stacks = Query(filter: #Predicate<Stack> { $0.boardId == boardID }, sort: \.order)
            // board query for title
            _boards = Query(filter: #Predicate<Board> { $0.id == boardID } )

        } else {
            _stacks = Query(filter: #Predicate<Stack> { _ in false })
            _boards = Query(filter: #Predicate<Board> { _ in false })
        }
    }

    private var boardTitle: String {
        boards.first?.title ?? "Stacks"
    }

    private var cardCounts: [Int: Int] {
        Dictionary(grouping: cards, by: \.stackId)
            .mapValues(\.count)
    }

    var body: some View {
        List(stacks, selection: $selectedStackID) { stack in
            let _ = print(stack.order)
            VStack(alignment: .leading) {
                Text(stack.title)

                Text(.cardCount(cardCounts[stack.id, default: 0]))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .tag(stack.id)        }
        .navigationTitle(boardTitle)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showNewStackSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewStackSheet) {
            NewStackSheet(boardId: boardID ?? 0)
        }
    }
}
