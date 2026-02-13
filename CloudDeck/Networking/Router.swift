//
//  DeckRouter.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Foundation
import SwiftUI

enum Method: String {
    case connect
    case delete
    case get
    case head
    case options
    case patch
    case post
    case put
    case trace

    var uppercased: String {
        return rawValue.uppercased()
    }
}

enum Router {
    case boards
    case board(id: Int)
    case stacks(boardId: Int)
    case cards(stackId: Int)
    case card(id: Int)

    case createBoard(title: String, hexColor: String)

    case createCard(boardId: Int, stackId: Int, title: String, description: String?)
    case updateCard(boardId: Int, stackId: Int, cardId: Int, title: String?, description: String?, type: String, owner: String, order: Int?, duedate: String?, archived: Bool?, done: String?)

    case assignLabel(boardId: Int, stackId: Int, cardId: Int, labelId: Int)
    case removeLabel(boardId: Int, stackId: Int, cardId: Int, labelId: Int)

    case assignUser(boardId: Int, stackId: Int, cardId: Int, userId: String)
    case unassignUser(boardId: Int, stackId: Int, cardId: Int, userId: String)

    private var method: Method {
        switch self {
        case .boards:
            return .get
        case .board, .stacks, .cards, .card:
            return .get
        case .createBoard, .createCard:
            return .post
        case .updateCard, .assignLabel, .removeLabel, .assignUser, .unassignUser:
            return .put
        }
    }

    private var path: String {
        switch self {
        case .boards:
            "/boards"
        case .createBoard(_, _):
            "/boards"
        case .board(let id):
            "/boards/\(id)"
        case .stacks(let boardId):
            "/boards/\(boardId)/stacks"
        case .cards(let stackId):
            "/stacks/\(stackId)/cards"
        case .card(let id):
            "/cards/\(id)"
        case .createCard(let boardId, let stackId, _, _):
            "/boards/\(boardId)/stacks/\(stackId)/cards"
        case .updateCard(let boardId, let stackId, let cardId, _, _, _, _, _, _, _, _):
            "/boards/\(boardId)/stacks/\(stackId)/cards/\(cardId)"
        case .assignLabel(let boardId, let stackId, let cardId, _):
            "/boards/\(boardId)/stacks/\(stackId)/cards/\(cardId)/assignLabel"
        case .removeLabel(let boardId, let stackId, let cardId, _):
            "/boards/\(boardId)/stacks/\(stackId)/cards/\(cardId)/removeLabel"
        case .assignUser(let boardId, let stackId, let cardId, _):
            "/boards/\(boardId)/stacks/\(stackId)/cards/\(cardId)/assignUser"
        case .unassignUser(let boardId, let stackId, let cardId, _):
            "/boards/\(boardId)/stacks/\(stackId)/cards/\(cardId)/unassignUser"
        }
    }

    private var body: Data? {
        switch self {

        case .updateCard(_, _, _, let title, let description, let type, let owner, let order, let duedate, let archived, let done):

            let payload: [String: Any?] = [
                "title": title,
                "description": description,
                "type": type,
                "owner": owner,
                "order": order,
                "archived": archived,
                "duedate": duedate,
                "done": done
            ]

            return try? JSONSerialization.data(
                withJSONObject: payload.compactMapValues { $0 }
            )

        case .createBoard(let title, let hexColor):
            let payload: [String: Any?] = [
                "title": title,
                "color": hexColor
            ]
            
            return try? JSONSerialization.data(
                withJSONObject: payload.compactMapValues { $0 }
                , options: [])

        case .createCard(_, _, let title, let description):
            let payload: [String: Any?] = [
                "title": title,
                "type": "plain",
                "order": 999,
                "description": description
            ]

            return try? JSONSerialization.data(
                withJSONObject: payload.compactMapValues { $0 }
            )

        case .assignLabel(_, _, _, let labelId), .removeLabel(_, _, _, let labelId):
            let payload: [String: Any?] = [
                "labelId": labelId
            ]
            
            return try? JSONSerialization.data(
                withJSONObject: payload.compactMapValues { $0 }
            )

        case .assignUser(_, _, _, let userId), .unassignUser(_, _, _, let userId):
            let payload: [String: Any?] = [
                "userId": userId
            ]

            return try? JSONSerialization.data(
                withJSONObject: payload.compactMapValues { $0 }
            )

        default:
            return nil
        }
    }
    
    private var basicAuthHeader: String {
        return ValetManager.shared.basicAuthHeader
    }

    func urlRequest() throws -> URLRequest {
        @AppStorage(Constants.Settings.server) var server: String = ""
        @AppStorage(Constants.Settings.etag) var etag: String = ""

        let baseURLString = "\(server)/index.php/apps/deck/api/v1.1"
        guard let url = URL(string: baseURLString) else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.uppercased
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.timeoutInterval = 20.0
        urlRequest.setValue(basicAuthHeader, forHTTPHeaderField: Constants.Headers.authorization)
        urlRequest.setValue("true", forHTTPHeaderField: Constants.Headers.ocsApiRequest)
        // urlRequest.setValue("Wed, 04 Feb 2026 00:17:06 GMT", forHTTPHeaderField: "If-Modified-Since")
        print(etag)
        urlRequest.setValue("application/json", forHTTPHeaderField: Constants.Headers.accept)

        // Only send ETag on GET
        if method == .get {
            urlRequest.setValue(etag, forHTTPHeaderField: Constants.Headers.ifNoneMatch)
        }

        if let body {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json", forHTTPHeaderField: Constants.Headers.contentType)
        }

        return urlRequest
    }

}
