//
//  DeckAPIClient.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import Foundation

final class DeckAPIClient {

    private let baseURL: URL
    private let username: String
    private let appPassword: String
    private let session: URLSession

    init(
        baseURL: URL,
        username: String,
        appPassword: String,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.username = username
        self.appPassword = appPassword
        self.session = session
    }

    func send<T: Decodable>(
        _ router: DeckRouter,
        etag: String? = nil
    ) async throws -> (T, String?) {

        let request = try router.asURLRequest(
            username: username,
            appPassword: appPassword,
            etag: etag
        )

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if http.statusCode == 304 {
            throw DeckError.notModified
        }

        let newETag = http.value(forHTTPHeaderField: "ETag")
        let decoded = try JSONDecoder().decode(T.self, from: data)

        return (decoded, newETag)
    }
}

enum DeckError: Error {
    case notModified
}
