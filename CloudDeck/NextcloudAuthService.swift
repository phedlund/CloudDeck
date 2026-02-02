//
//  NextcloudAuthService.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftUI
import AuthenticationServices

struct NextcloudFlowResponse: Decodable {
    let login: String
    let poll: NextcloudPollInfo
}

struct NextcloudPollInfo: Decodable {
    let endpoint: String
    let token: String
}

struct NextcloudCredentials: Decodable, Equatable {
    let server: String
    let loginName: String
    let appPassword: String
}

enum LoginError: LocalizedError {
    case invalidURL
    case serverError
    case timeout
    case cancelled
    case invalidServerURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .serverError:
            return "Server error occurred"
        case .timeout:
            return "Login timeout - please try again"
        case .cancelled:
            return "Login cancelled"
        case .invalidServerURL:
            return "Please enter a valid Nextcloud server URL"
        }
    }
}

@Observable
class NextcloudAuthService {
    var isAuthenticating = false
    var credentials: NextcloudCredentials?

    let userAgent: String = {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let appName = displayName ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        return "Mozilla/5.0 (iOS)/\(appName ?? "")/\(appVersion ?? "")"
    }()

    @MainActor
    func executeFullAuth(serverURL: URL, session: WebAuthenticationSession) async {
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            // 1. Get initial Nextcloud Flow data
            let flow = try await fetchFlowInfo(serverURL: serverURL)

            // 2. Run Browser and Polling in parallel
            try await withThrowingTaskGroup(of: NextcloudCredentials?.self) { group in

                // Task A: The Browser UI
                group.addTask {
                    // This waits for the user to finish the web flow
                    _ = try await session.authenticate(
                        using: flow.loginURL,
                        callback: .customScheme("nc"),
                        preferredBrowserSession: nil,
                        additionalHeaderFields: [
                            "User-Agent": self.userAgent,
                            "OCS-APIRequest": "true"
                        ]
                    )
                    return nil // Browser finished, but polling usually provides the password
                }

                // Task B: The Background Polling
                group.addTask {
                    return try await self.pollForPassword(endpoint: flow.pollEndpoint, token: flow.pollToken)
                }

                // 3. Process results as they arrive
//                do {
                    // This loop will run for each task in the group
                    for try await result in group {
                        if let credentials = result {
                            // If the poller returns the password, save it and stop everything
                            self.credentials = credentials
                            group.cancelAll()
                            return
                        }
                    }
//                } catch {
//                    // Handles 'User Cancelled' from ASWebAuthenticationSession
//                    print("Authentication flow interrupted: \(error.localizedDescription)")
//                    group.cancelAll()
//                }

                // 4. Cancel everything else in the group (stops polling)
                group.cancelAll()
            }
        } catch {
            print("Auth Flow Error: \(error)")
        }
    }

    private func fetchFlowInfo(serverURL: URL) async throws -> (loginURL: URL, pollEndpoint: URL, pollToken: String) {
        let flowURL = serverURL.appending(path: "/index.php/login/v2")
        var request = URLRequest(url: flowURL)
        request.httpMethod = "POST"
        request.addValue("true", forHTTPHeaderField: "OCS-APIRequest")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)

        // Nextcloud OCS responses are often nested under a "poll" key
        let response = try JSONDecoder().decode(NextcloudFlowResponse.self, from: data)

        guard let loginURL = URL(string: response.login),
              let pollURL = URL(string: response.poll.endpoint) else {
            throw URLError(.badURL)
        }

        return (loginURL, pollURL, response.poll.token)
    }


    private func pollForPassword(endpoint: URL, token: String) async throws -> NextcloudCredentials {
        while !Task.isCancelled {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.httpBody = "token=\(token)".data(using: .utf8)
            request.addValue("true", forHTTPHeaderField: "OCS-APIRequest")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

            // 1. Perform the network call
            if let (data, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {

                // 2. Decode the final OCS response
                let result = try JSONDecoder().decode(NextcloudCredentials.self, from: data)
                return result
            }

            // 3. Wait before retrying (Standard Nextcloud interval is 5s)
            try await Task.sleep(for: .seconds(5))
        }
        throw CancellationError()
    }

}
