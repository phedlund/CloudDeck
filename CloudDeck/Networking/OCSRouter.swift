//
//  OCSRouter.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/16/26.
//

import Foundation
import SwiftUI

enum OCSRouter {
    case users(id: String)
    case capabilities

    private var method: Method {
        switch self {
        case .users:
            return .get
        case .capabilities:
            return .get
        }
    }

    private var path: String {
        switch self {
            
        case .users(let id):
            "/users/\(id)"
        case .capabilities:
            "/capabilities"
        }
    }

    private var basicAuthHeader: String {
        return ValetManager.shared.basicAuthHeader
    }

    func urlRequest() throws -> URLRequest {
        @AppStorage(Constants.Settings.server) var server: String = ""

        let baseURLString = "\(server)/ocs/v1.php/cloud"
        guard let url = URL(string: baseURLString) else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.uppercased
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.timeoutInterval = 20.0
        urlRequest.setValue(basicAuthHeader, forHTTPHeaderField: Constants.Headers.authorization)
        urlRequest.setValue("true", forHTTPHeaderField: Constants.Headers.ocsApiRequest)
        urlRequest.setValue(Constants.Headers.contentTypeJson, forHTTPHeaderField: Constants.Headers.accept)
        return urlRequest
    }

}
