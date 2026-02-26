//
//  StatusRouter.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/25/26.
//

import Foundation
import SwiftUI

enum StatusRouter {
    case status

    private var method: Method {
        switch self {
        case .status:
            return .get
        }
    }

    // MARK: URLRequest

    func urlRequest() throws -> URLRequest {
        @AppStorage(Constants.Settings.server) var server: String = ""

        switch self {
        case .status:
            let baseURLString = "\(server)/status.php"
            guard let url = URL(string: baseURLString) else {
                throw URLError(.badURL)
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method.uppercased
            urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
            urlRequest.timeoutInterval = 20.0
            urlRequest.setValue("true", forHTTPHeaderField: Constants.Headers.ocsApiRequest)
            urlRequest.setValue(Constants.Headers.contentTypeJson, forHTTPHeaderField: Constants.Headers.accept)
            return urlRequest
        }
    }
}
