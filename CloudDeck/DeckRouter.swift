//
//  DeckRouter.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Foundation

enum Method: String {
    case connect = "CONNECT"
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case trace = "TRACE"
}

enum DeckRouter {
        case boards
        case board(id: Int)
        case stacks(boardId: Int)
        case cards(stackId: Int)
        case card(id: Int)

//    let baseURL: URL
//    let endpoint: Endpoint
//    let method: Method
//    let queryItems: [URLQueryItem]?
//    let body: Data?

    private var method: Method {
        switch self {
//        case .feeds, .folders, .items, .updatedItems, .version, .status, .favicon:
//            return .get
//        case .addFeed, .addFolder, .itemsRead, .itemsUnread, .itemStarred, .itemUnstarred, .itemsStarred, .itemsUnstarred, .markFeedRead, .renameFeed, .moveFeed, .markFolderRead, .itemRead, .itemUnread, .allItemsRead:
//            return .post
//        case .deleteFeed, .deleteFolder:
//            return .delete
//        case .renameFolder:
//            return .put
        default:
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
        let server = UserDefaults.standard.string(forKey: "serverURL")
        let baseURLString = "\(String(describing: server))/index.php/apps/deck/api/v1.0"
        let url = URL(string: baseURLString)! //FIX

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.timeoutInterval = 20.0
        urlRequest.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
            //                case .folders, .feeds:
        default:
            URLRequest(url: url)
        }
        return urlRequest
    }
//    func asURLRequest(
//        username: String,
//        appPassword: String,
//        etag: String? = nil
//    ) throws -> URLRequest {
//
//        var components = URLComponents(
//            url: baseURL.appendingPathComponent(path),
//            resolvingAgainstBaseURL: false
//        )
//        components?.queryItems = queryItems
//
//        guard let url = components?.url else {
//            throw URLError(.badURL)
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = method.rawValue.uppercased()
//        request.httpBody = body
//
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let auth = "\(username):\(appPassword)"
//        let encoded = Data(auth.utf8).base64EncodedString()
//        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
//
//        if let etag {
//            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
//        }
//
//        return request
//    }

}

//extension DeckRouter {
//
//    static func paginatedCards(
//        baseURL: URL,
//        stackId: Int,
//        limit: Int,
//        offset: Int
//    ) -> DeckRouter {
//
//        DeckRouter(
//            baseURL: baseURL,
//            endpoint: .cards(stackId: stackId),
//            method: .get,
//            queryItems: [
//                .init(name: "limit", value: "\(limit)"),
//                .init(name: "offset", value: "\(offset)")
//            ],
//            body: nil
//        )
//    }
//}
