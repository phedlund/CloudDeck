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
        let boardIDs = try await syncBoards()
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
                if let deckBoardDTOs = try? decoder.decode([BoardDTO].self, from: data) {
                    for deckBoardDTO in deckBoardDTOs  {
                        await backgroundActor.upsert(deckBoardDTO)
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

    private func repeatSync() async throws {

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
