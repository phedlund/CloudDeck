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

    private var method: Method {
        switch self {
        case .boards:
            return .get
        case .board, .stacks, .cards, .card:
            return .get
        }
    }

    private var path: String {
        switch self {
        case .boards:
            "/boards"
        case .board(let id):
            "/boards/\(id)"
        case .stacks(let boardId):
            "/boards/\(boardId)/stacks"
        case .cards(let stackId):
            "/stacks/\(stackId)/cards"
        case .card(let id):
            "/cards/\(id)"
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
        urlRequest.setValue(etag, forHTTPHeaderField: Constants.Settings.etag)
        urlRequest.setValue("application/json", forHTTPHeaderField: Constants.Headers.accept)

        switch self {
        case .boards:
            break
        case .board(let id):
            break
        case .stacks(let boardId):
            break
        case .cards(let stackId):
            break
        case .card(let id):
            break
        }

        return urlRequest
    }
}
