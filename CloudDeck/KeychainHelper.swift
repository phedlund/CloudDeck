//
//  KeychainHelper.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/31/26.
//

import Foundation
import Security

/// Helper for storing and retrieving credentials from the iOS/macOS Keychain
struct KeychainHelper {
    /// Save a password to the Keychain
    /// - Parameters:
    ///   - password: The password to store
    ///   - key: The key to store it under (typically "serverURL_username")
    static func save(_ password: String, for key: String) {
        let data = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Retrieve a password from the Keychain
    /// - Parameter key: The key to look up
    /// - Returns: The password if found, nil otherwise
    static func get(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    /// Delete a password from the Keychain
    /// - Parameter key: The key to delete
    static func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
