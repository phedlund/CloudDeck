//
//  DeckRouter.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Foundation

struct DeckRouter {

    enum Method: String {
        case get, post, put, delete
    }

    enum Endpoint {
        case boards
        case board(id: Int)
        case stacks(boardId: Int)
        case cards(stackId: Int)
        case card(id: Int)
    }

    let baseURL: URL
    let endpoint: Endpoint
    let method: Method
    let queryItems: [URLQueryItem]?
    let body: Data?

    func asURLRequest(
        username: String,
        appPassword: String,
        etag: String? = nil
    ) throws -> URLRequest {

        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue.uppercased()
        request.httpBody = body

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let auth = "\(username):\(appPassword)"
        let encoded = Data(auth.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")

        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        return request
    }

    private var path: String {
        switch endpoint {
        case .boards:
            "/apps/deck/api/v1.0/boards"
        case .board(let id):
            "/apps/deck/api/v1.0/boards/\(id)"
        case .stacks(let boardId):
            "/apps/deck/api/v1.0/boards/\(boardId)/stacks"
        case .cards(let stackId):
            "/apps/deck/api/v1.0/stacks/\(stackId)/cards"
        case .card(let id):
            "/apps/deck/api/v1.0/cards/\(id)"
        }
    }
}

extension DeckRouter {

    static func paginatedCards(
        baseURL: URL,
        stackId: Int,
        limit: Int,
        offset: Int
    ) -> DeckRouter {

        DeckRouter(
            baseURL: baseURL,
            endpoint: .cards(stackId: stackId),
            method: .get,
            queryItems: [
                .init(name: "limit", value: "\(limit)"),
                .init(name: "offset", value: "\(offset)")
            ],
            body: nil
        )
    }
}
