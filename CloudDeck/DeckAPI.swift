//
//  DeckAPIClient.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Foundation

final class DeckAPI {

    private let baseURL: URL
    private let username: String
    private let appPassword: String
    private let session: URLSession

    init(account: Account, session: URLSession = .shared) {
        self.baseURL = URL(string: account.serverURL)!
        self.username = account.username
        self.appPassword = account.appPassword
        self.session = session
    }

//    func send<T: Decodable>(_ router: DeckRouter, etag: String? = nil) async throws -> (T, String?) {
//
//        let request = try router.asURLRequest(
//            username: username,
//            appPassword: appPassword,
//            etag: etag
//        )
//
//        let (data, response) = try await session.data(for: request)
//
//        guard let http = response as? HTTPURLResponse else {
//            throw URLError(.badServerResponse)
//        }
//
//        if http.statusCode == 304 {
//            throw DeckError.notModified
//        }
//
//        let newETag = http.value(forHTTPHeaderField: "ETag")
//        let decoded = try JSONDecoder().decode(T.self, from: data)
//
//        return (decoded, newETag)
//    }

    /// Fetch all boards from the remote service.
    /// - Returns: An array of `DeckBoardDTO` from the server.
    func fetchBoards() async throws -> [DeckBoardDTO] {
//        let router = DeckRouter(baseURL: baseURL, endpoint: .boards, method: .get, queryItems: <#T##[URLQueryItem]?#>, body: <#T##Data?#>)
        // TODO: Implement network request to fetch boards
        // Example: return try await httpClient.get("/boards")
        return []
    }

    /// Fetch all stacks for a specific board from the remote service.
    /// - Parameter boardId: The identifier of the board to fetch stacks for.
    /// - Returns: An array of `DeckStackDTO` from the server.
    public static func fetchStacks(boardId: Int) async throws -> [DeckStackDTO] {
        // TODO: Implement network request to fetch stacks for a board
        // Example: return try await httpClient.get("/boards/\(boardId)/stacks")
        return []
    }

    /// Fetch all cards for a specific stack from the remote service.
    /// - Parameter stackId: The identifier of the stack to fetch cards for.
    /// - Returns: An array of `DeckCardDTO` from the server.
    public static func fetchCards(stackId: Int) async throws -> [DeckCardDTO] {
        // TODO: Implement network request to fetch cards for a stack
        // Example: return try await httpClient.get("/stacks/\(stackId)/cards")
        return []
    }


}

enum DeckError: Error {
    case notModified
}
