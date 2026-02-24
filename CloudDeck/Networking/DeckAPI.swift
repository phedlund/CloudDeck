//
//  DeckAPIClient.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Foundation
import SwiftData

@Observable
final class DeckAPI {
    private let backgroundActor: DeckModelActor
    private let backgroundSession: URLSession
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [
            .withInternetDateTime,
            .withColonSeparatorInTimeZone
        ]
        return f
    }()

    init(modelContainer: ModelContainer) {
        self.backgroundActor = DeckModelActor(modelContainer: modelContainer)
        let backgroundSessionConfig = URLSessionConfiguration.background(withIdentifier: "dev.pbh.clouddeck.background")
        backgroundSessionConfig.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: backgroundSessionConfig)
    }

    func sync() async throws /*-> NewsStatusDTO? */ {
//        syncState = .started
//        let hasItems = await backgroundActor.hasItems()
//        let currentStatus = try await newsStatus()
//        if hasItems && lastModified > 0 {
        let boardIDs = try await syncBoards()
        try await syncBoardDetails(boardIDs: boardIDs)
        try await syncStacks(boardIDs: boardIDs)
//        } else {
//            try await initialSync()
//            if !hasItems {
//                syncState = .favicons
//                await getFavIcons()
//            }
//            syncState = .idle
//        }
//        WidgetCenter.shared.reloadAllTimelines()
//        return currentStatus
    }

    private func syncBoards() async throws -> [Int] {
        var result = [Int]()
        let boardRequest = try Router.boards.urlRequest()
        let (data, response) = try await URLSession.shared.data(for: boardRequest)
        if let response = response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
                if let etag = response.value(forHTTPHeaderField: Constants.Settings.etag) {
                    UserDefaults.standard.set(etag, forKey: Constants.Settings.etag)
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                if let deckBoardDTOs = try? decoder.decode([BoardSummaryDTO].self, from: data) {
                    for deckBoardDTO in deckBoardDTOs  {
                        await backgroundActor.insert(deckBoardDTO)
                    }
                    try? await backgroundActor.save()
                    result = deckBoardDTOs.map((\.id))
                }
            case 304:
                print("304")
            case 401:
                print("401")
            default:
                print("unknown status code: \(response.statusCode)")
            }
        }
        return result
    }

    private func syncBoardDetails(boardIDs: [Int]) async throws {
        for boardId in boardIDs {
            let (data, response) = try await URLSession.shared.data(for: Router.board(id: boardId).urlRequest())
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200:
                    let headers = response.allHeaderFields
                    for header in headers {
                        print("\(header.key): \(header.value)")
                    }

                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let boardDTO = try? decoder.decode(BoardDetailDTO.self, from: data) {
                        try? await backgroundActor.insert(boardDTO)
                        try? await backgroundActor.save()
                    }
                case 304:
                    print("304")
                case 401:
                    print("401")
                default:
                    print("unknown status code: \(response.statusCode)")
                }
            }
        }

    }

    private func syncStacks(boardIDs: [Int]) async throws {
        for boardId in boardIDs {
            let (data, response) = try await URLSession.shared.data(for: Router.stacks(boardId: boardId).urlRequest())
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200:
                    let headers = response.allHeaderFields
                    for header in headers {
                        print("\(header.key): \(header.value)")
                    }

                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let deckStackDTOs = try? decoder.decode([StackDTO].self, from: data) {
                        for stackDTO in deckStackDTOs {
                            try await backgroundActor.addStack(stackDTO)
                        }
                        try? await backgroundActor.save()
                    }
                case 304:
                    print("304")
                case 401:
                    print("401")
                default:
                    print("unknown status code: \(response.statusCode)")
                }
            }
        }
    }

    func createBoard(title: String, colorHex: String) async throws {
        let request = try Router.createBoard(title: title, hexColor: colorHex)
            .urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }
        let boardDTO = try JSONDecoder().decode(BoardSummaryDTO.self, from: data)
        await backgroundActor.insert(boardDTO)
        try await syncBoardDetails(boardIDs: [boardDTO.id])
    }

    func updateBoard(boardId: Int, title: String, color: String, archived: Bool) async throws {
        let request = try Router.updateBoard(id: boardId, title: title, color: color, archived: archived)
            .urlRequest()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let boardDTO = try? decoder.decode(BoardDetailDTO.self, from: data) {
            try await backgroundActor.insert(boardDTO)
            try? await backgroundActor.save()
        }

    }

    func deleteBoard(boardId: Int) async throws {
        let request = try Router.deleteBoard(id: boardId)
            .urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }
    }

    func createStack(boardId: Int, title: String, order: Int) async throws {
        let request = try Router.createStack(boardId: boardId, title: title, order: order)
            .urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let deckStackDTO = try? decoder.decode(StackDTO.self, from: data) {
            try await backgroundActor.addStack(deckStackDTO)
            try? await backgroundActor.save()
        }
    }

    func updateStack(boardId: Int, stackId: Int, title: String, order: Int) async throws {
        let request = try Router.updateStack(
            boardId: boardId,
            stackId: stackId,
            title: title,
            order: order
            ).urlRequest()
        
        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let deckStackDTO = try? decoder.decode(StackDTO.self, from: data) {
            try await backgroundActor.addStack(deckStackDTO)
            try? await backgroundActor.save()
        }
    }

    func deleteStack(boardId: Int, stackId: Int) async throws {
        let request = try Router.deleteStack(boardId: boardId, stackId: stackId).urlRequest()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }
    }

    func createCard(boardId: Int, stackId: Int, title: String, description: String? = nil) async throws -> CardDTO {
        let request = try Router.createCard(
            boardId: boardId,
            stackId: stackId,
            title: title,
            description: description
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }
        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
        return cardDTO
    }

    func updateCard(_ card: Card) async throws {

        var dueDateString: String?
        if let dueDate = card.dueDate {
           dueDateString = iso.string(from: dueDate)
        }

        var doneString: String?
        if let doneAt = card.doneAt {
            doneString = iso.string(from: doneAt)
        }

        let request = try Router.updateCard(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            title: card.title,
            description: card.cardDescription,
            type: card.type,
            owner: card.owner.uid,
            order: card.order,
            duedate: dueDateString,
            archived: card.archived,
            done: doneString
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw DeckError.serverError
        }

        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
    }

    func moveCard(_ card: Card, newBoardId: Int, newStackId: Int) async throws {

        var dueDateString: String?
        if let dueDate = card.dueDate {
           dueDateString = iso.string(from: dueDate)
        }

        var doneString: String?
        if let doneAt = card.doneAt {
            doneString = iso.string(from: doneAt)
        }

        let request = try Router.updateCard(
            boardId: newBoardId,
            stackId: newStackId,
            cardId: card.id,
            title: card.title,
            description: card.cardDescription,
            type: card.type,
            owner: card.owner.uid,
            order: card.order,
            duedate: dueDateString,
            archived: card.archived,
            done: doneString
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw DeckError.serverError
        }

        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
    }

    func copyCard(_ card: Card, newBoardId: Int, newStackId: Int) async throws {
        let newCardDTO = try await createCard(boardId: newBoardId, stackId: newStackId, title: card.title, description: card.cardDescription)

        var dueDateString: String?
        if let dueDate = card.dueDate {
           dueDateString = iso.string(from: dueDate)
        }

        var doneString: String?
        if let doneAt = card.doneAt {
            doneString = iso.string(from: doneAt)
        }

        let request = try Router.updateCard(
            boardId: newBoardId,
            stackId: newStackId,
            cardId: newCardDTO.id,
            title: newCardDTO.title,
            description: newCardDTO.description,
            type: newCardDTO.type,
            owner: newCardDTO.owner.uid,
            order: newCardDTO.order,
            duedate: dueDateString,
            archived: newCardDTO.archived,
            done: doneString
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw DeckError.serverError
        }

        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
    }

    func setCardDone(card: Card, done: Bool) async throws {

        var dueDateString: String?
        if let dueDate = card.dueDate {
           dueDateString = iso.string(from: dueDate)
        }

        var doneString: String?
        if done {
            doneString = iso.string(from: Date())
        }

        let request = try Router.updateCard(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            title: card.title,
            description: card.cardDescription,
            type: card.type,
            owner: card.owner.uid,
            order: card.order,
            duedate: dueDateString,
            archived: false,
            done: doneString
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }
        
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw DeckError.serverError
        }

        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
    }

    func setCardDueDate(card: Card, dueDate: Date?) async throws {

        var dueDateString: String?
        if let dueDate {
           dueDateString = iso.string(from: dueDate)
        }

        var doneString: String?
        if let doneAt = card.doneAt {
            doneString = iso.string(from: doneAt)
        }

        let request = try Router.updateCard(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            title: card.title,
            description: card.cardDescription,
            type: card.type,
            owner: card.owner.uid,
            order: card.order,
            duedate: dueDateString,
            archived: card.archived,
            done: doneString
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw DeckError.serverError
        }

        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
    }

    func setCardArchived(card: Card, archived: Bool) async throws {

        var dueDateString: String?
        if let dueDate = card.dueDate {
           dueDateString = iso.string(from: dueDate)
        }

        var doneString: String?
        if let doneAt = card.doneAt {
            doneString = iso.string(from: doneAt)
        }

        let request = try Router.updateCard(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            title: card.title,
            description: card.cardDescription,
            type: card.type,
            owner: card.owner.uid,
            order: card.order,
            duedate: dueDateString,
            archived: archived,
            done: doneString
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw DeckError.serverError
        }

        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
    }

    // New API
    func archiveCard(boardId: Int, stackId: Int, cardId: Int) async throws {
        let request = try Router.archiveCard(boardId: boardId, stackId: stackId, cardId: cardId).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw DeckError.serverError
        }

        let cardDTO = try JSONDecoder().decode(CardDTO.self, from: data)
        try await backgroundActor.addCard(from: cardDTO)
    }

    func deleteCard(boardId: Int, stackId: Int, cardId: Int) async throws {
        let request = try Router.deleteCard(boardId: boardId, stackId: stackId, cardId: cardId).urlRequest()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DeckError.serverError
        }
    }

    func assignCardLabel(card: Card, label: DeckLabel) async throws {

        let request = try Router.assignLabel(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            labelId: label.id
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        if let response = response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
                try await updateCard(card)
            default:
                throw DeckError.serverError
            }
        }
    }

    func removeCardLabel(card: Card, label: DeckLabel) async throws {

        let request = try Router.removeLabel(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            labelId: label.id
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        if let response = response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
                let filteredLabels = card.labels.filter( { $0.id != label.id } )
                card.labels = filteredLabels
            default:
                throw DeckError.serverError
            }
        }
    }

    func assignUser(card: Card, user: User) async throws {

        let request = try Router.assignUser(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            userId: user.uid
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        if let response = response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
                try await updateCard(card)
            default:
                throw DeckError.serverError
            }
        }
    }

    func unassignUser(card: Card, user: User) async throws {

        let request = try Router.unassignUser(
            boardId: card.stack?.boardId ?? 0,
            stackId: card.stackId,
            cardId: card.id,
            userId: user.uid
        ).urlRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let body = String(data: data, encoding: .utf8) {
            print("SERVER BODY:", body)
        }

        if let response = response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
                if let index = card.assignedUsers.firstIndex(where: { $0.user.uid  == user.uid } ) {
                    card.assignedUsers.remove(at: index)
                }
            default:
                throw DeckError.serverError
            }
        }
    }

}

enum DeckError: Error {
    case notModified
    case serverError
}
