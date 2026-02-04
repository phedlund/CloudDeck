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
            try await syncBoards()
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

    private func syncBoards() async throws {
        let requests = try await syncRequests()
        let (data, response) = try await URLSession.shared.data(for: requests.boardRequest)
        if let response = response as? HTTPURLResponse {
            switch response.statusCode {
            case 200:
                let headers = response.allHeaderFields
                for header in headers {
                    print("\(header.key): \(header.value)")
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                guard let decodedResponse = try? decoder.decode([BoardDTO].self, from: data) else {
                    //                    throw NetworkError.generic(message: "Unable to decode")
                    return
                }
                for deckBoardDTO in decodedResponse  {
                    await backgroundActor.upsert(deckBoardDTO)
                }
                try? await backgroundActor.save()

                break
            case 304:
                print("304")
            case 401:
                print("401")
            default:
                print("unknown status code: \(response.statusCode)")
            }
        }

//        try await backgroundActor.save(boardsResponse)
    }

    private func repeatSync() async throws {
//        var localReadIds = [Int64]()
//        let identifiers = try await backgroundActor.allModelIds(FetchDescriptor<Read>())
//        for identifier in identifiers {
//            if let itemId = try await backgroundActor.fetchItemId(by: identifier) {
//                localReadIds.append(itemId)
//            }
//        }
//
//        if !localReadIds.isEmpty {
//            let readParameters = ["items": localReadIds]
//            let readRouter = Router.itemsRead(parameters: readParameters)
//            async let (_, readResponse) = URLSession.shared.data(for: readRouter.urlRequest(), delegate: nil)
//            let readItemsResponse = try await readResponse
//            if let httpReadResponse = readItemsResponse as? HTTPURLResponse {
//                switch httpReadResponse.statusCode {
//                case 200:
//                    try await backgroundActor.delete(model: Read.self)
//                default:
//                    break
//                }
//            }
//        }
//
//        var localUnreadIds = [Int64]()
//        let unreadIdentifiers = try await backgroundActor.allModelIds(FetchDescriptor<Unread>())
//        for identifier in unreadIdentifiers {
//            if let itemId = try await backgroundActor.fetchItemId(by: identifier) {
//                localUnreadIds.append(itemId)
//            }
//        }
//
//        if !localUnreadIds.isEmpty {
//            let unreadParameters = ["itemIds": localUnreadIds]
//            let unreadRouter = Router.itemsUnread(parameters: unreadParameters)
//            async let (_, unreadResponse) = URLSession.shared.data(for: unreadRouter.urlRequest(), delegate: nil)
//            let unreadItemsResponse = try await unreadResponse
//            if let httpUnreadResponse = unreadItemsResponse as? HTTPURLResponse {
//                switch httpUnreadResponse.statusCode {
//                case 200:
//                    try await backgroundActor.delete(model: Unread.self)
//                default:
//                    break
//                }
//            }
//        }
//
//        var localStarredIds = [Int64]()
//        let starredIdentifiers = try await backgroundActor.allModelIds(FetchDescriptor<Starred>())
//        for identifier in starredIdentifiers {
//            if let itemId = try await backgroundActor.fetchItemId(by: identifier) {
//                localStarredIds.append(itemId)
//            }
//        }
//
//        if !localStarredIds.isEmpty {
//            let starredParameters = ["itemIds": localStarredIds]
//            let starredRouter = Router.itemsStarred(parameters: starredParameters)
//            async let (_, starredResponse) = URLSession.shared.data(for: starredRouter.urlRequest(), delegate: nil)
//            let starredItemsResponse = try await starredResponse
//            if let httpStarredResponse = starredItemsResponse as? HTTPURLResponse {
//                switch httpStarredResponse.statusCode {
//                case 200:
//                    try await backgroundActor.delete(model: Starred.self)
//                default:
//                    break
//                }
//            }
//        }
//
//        var localUnstarredIds = [Int64]()
//        let unStarredIdentifiers = try await backgroundActor.allModelIds(FetchDescriptor<Unstarred>())
//        for identifier in unStarredIdentifiers {
//            if let itemId = try await backgroundActor.fetchItemId(by: identifier) {
//                localUnstarredIds.append(itemId)
//            }
//        }
//
//        if !localUnstarredIds.isEmpty {
//            let unstarredParameters = ["itemIds": localUnstarredIds]
//            let unstarredRouter = Router.itemsStarred(parameters: unstarredParameters)
//            async let (_, unstarredResponse) = URLSession.shared.data(for: unstarredRouter.urlRequest(), delegate: nil)
//            let unstarredItemsResponse = try await unstarredResponse
//            if let httpUnstarredResponse = unstarredItemsResponse as? HTTPURLResponse {
//                switch httpUnstarredResponse.statusCode {
//                case 200:
//                    try await backgroundActor.delete(model: Unstarred.self)
//                default:
//                    break
//                }
//            }
//        }

        let syncRequests = try await syncRequests()

        let results = try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            var results = [Int: Data]()

//            group.addTask { [self] in
//                try await pruneItems()
//                return (0, Data())
//            }
            group.addTask {
                return (1, try await URLSession.shared.data (for: syncRequests.boardRequest).0)
            }
            group.addTask {
                return (2, try await URLSession.shared.data (for: syncRequests.stackRequest).0)
            }
            group.addTask {
                return (3, try await URLSession.shared.data (for: syncRequests.cardRequest).0)
            }

            for try await (index, result) in group {
                results[index] = result
            }

            return results
        }

        if let boardData = results[1] as Data?, !boardData.isEmpty {
//            syncState = .folders
            await parseBoards(data: boardData)
        }
        if let stackData = results[2] as Data?, !stackData.isEmpty {
//            syncState = .feeds
//            await parseFeeds(data: stackData)
        }
        if let cardData = results[3] as Data?, !cardData.isEmpty {
//            syncState = .articles(current: 0, total: 0)
//            await parseItems(data: cardData)
        }
    }

    private func parseBoards(data: Data) async {
//        logger.info("Parsing folders")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let decodedResponse = try? decoder.decode([BoardDTO].self, from: data) else {
            //                    throw NetworkError.generic(message: "Unable to decode")
            return
        }
        for deckBoardDTO in decodedResponse  {
            await backgroundActor.upsert(deckBoardDTO)
        }
        try? await backgroundActor.save()
    }

}

enum DeckError: Error {
    case notModified
}
