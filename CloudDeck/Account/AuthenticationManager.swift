//
//  AuthenticationManager.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//


import SwiftUI
import SwiftData
import Valet

@Observable
@MainActor
class AuthenticationManager {
    @ObservationIgnored @AppStorage(Constants.Settings.server) var server = ""

    var isAuthenticated = false

    init() {
        checkAuthentication()
    }

    func checkAuthentication() {
        if server.isEmpty || ValetManager.shared.basicAuthHeader.isEmpty {
            isAuthenticated = false
        } else {
            isAuthenticated = true
        }
    }

    func currentAccount() -> Account? {
        if server.isEmpty || ValetManager.shared.basicAuthHeader.isEmpty {
            return nil
        }
        if let username = try? ValetManager.shared.valet.string(forKey: Constants.Settings.username), let password = try? ValetManager.shared.valet.string(forKey: Constants.Settings.password) {
            return Account(
                serverURL: server,
                username: username,
                appPassword: password
            )
        }
        return nil
    }

    func login(credentials: NextcloudCredentials) {
        // Save credentials
        server = credentials.server
        do {
            try ValetManager.shared.saveCredentials(username: credentials.loginName, password: credentials.appPassword)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func logout() {
        ValetManager.shared.logOut()
        server = ""
        isAuthenticated = false
    }
}
