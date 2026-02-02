//
//  URLSanitizer.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import Foundation

/// Utility for sanitizing and validating user-provided Nextcloud server URLs
struct URLSanitizer {
    /// Sanitizes and validates a user-provided Nextcloud server URL
    /// - Parameter input: The raw user input (e.g., "cloud.example.com", "https://example.com/")
    /// - Returns: A Result containing either the sanitized URL or a LoginError
    static func sanitize(_ input: String) -> Result<String, LoginError> {
        var sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove trailing slashes
        while sanitized.hasSuffix("/") {
            sanitized.removeLast()
        }

        // If no protocol is specified, assume HTTPS
        if !sanitized.lowercased().hasPrefix("http://") && !sanitized.lowercased().hasPrefix("https://") {
            sanitized = "https://" + sanitized
        }

        // Validate URL structure
        guard let url = URL(string: sanitized),
              let host = url.host,
              !host.isEmpty else {
            return .failure(.invalidServerURL)
        }

        // Reconstruct URL to ensure it's clean
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = host
        components.port = url.port
        components.path = url.path

        guard let finalURL = components.url?.absoluteString else {
            return .failure(.invalidServerURL)
        }

        return .success(finalURL)
    }
}

