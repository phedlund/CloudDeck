//
//  DeckAPIClient.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Foundation
import SwiftData

struct SyncRequests {
    let boardRequest: URLRequest
    let stackRequest: URLRequest
    let cardRequest: URLRequest
}

@Observable
final class DeckAPI {
    

//    Sun, 03 Aug 2019 10:34:12 GMT

    //EXAMPLE:  "Mon, 19 Oct 2015 05:57:12 GMT"
//        let date = httpResp.allHeaderFields["Last-Modified"] as! String
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
//        serverDate = dateFormatter.dateFromString(date) as NSDate?

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

    private let deckDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return f
    }()

    init(modelContainer: ModelContainer) {
        self.backgroundActor = DeckModelActor(modelContainer: modelContainer)
        let backgroundSessionConfig = URLSessionConfiguration.background(withIdentifier: "dev.pbh.clouddeck.background")
        backgroundSessionConfig.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: backgroundSessionConfig)
    }


    private func syncRequests() async throws -> SyncRequests {
        let boardRequest = try Router.boards.urlRequest()
        let stackRequest = try Router.stacks(boardId: 1).urlRequest()
        let cardRequest = try Router.cards(stackId: 1).urlRequest()

        return SyncRequests(boardRequest: boardRequest, stackRequest: stackRequest, cardRequest: cardRequest)
    }

    func sync() async throws /*-> NewsStatusDTO? */ {
//        syncState = .started
//        let hasItems = await backgroundActor.hasItems()
//        let currentStatus = try await newsStatus()
//        if hasItems && lastModified > 0 {
        let boardIDs = try await syncBoards()
        try await getBoardDetails(boardIDs: boardIDs)
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
        let requests = try await syncRequests()
        let (data, response) = try await URLSession.shared.data(for: requests.boardRequest)
        if let response = response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
//                let headers = response.allHeaderFields
//                for header in headers {
//                    print("\(header.key): \(header.value)")
//                }
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

    private func getBoardDetails(boardIDs: [Int]) async throws {
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
                        await backgroundActor.insert(boardDTO)
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
                        try await backgroundActor.apply(stackDTOs: deckStackDTOs, boardID: boardId)
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
        try await getBoardDetails(boardIDs: [boardDTO.id])
    }

    func createCard(boardId: Int, stackId: Int, title: String, description: String? = nil) async throws {
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
        try await backgroundActor.insertNewCard(from: cardDTO)
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
        try await backgroundActor.insertNewCard(from: cardDTO)
    }


    func setCardDone(card: Card, done: Bool) async throws {

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
            duedate: nil,
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
        try await backgroundActor.insertNewCard(from: cardDTO)
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
        try await backgroundActor.insertNewCard(from: cardDTO)
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
//                try await updateCard(card)
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
