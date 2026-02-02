//
//  AuthenticationManager.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//


import SwiftUI
import SwiftData

@Observable
@MainActor
class AuthenticationManager {
    @ObservationIgnored @AppStorage(SettingKeys.server) var server = ""

    var isAuthenticated = false
    var currentAccount: Account?

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

    func login(credentials: NextcloudCredentials) {
        // Save credentials
        server = credentials.server
        do {
            try ValetManager.shared.saveCredentials(username: credentials.loginName, password: credentials.appPassword)
        } catch {
            //
        }

        currentAccount = Account(
            serverURL: credentials.server,
            username: credentials.loginName,
            appPassword: credentials.appPassword
        )

        isAuthenticated = true
    }

    func logout() {
//        guard let account = currentAccount else { return }

        ValetManager.shared.logOut()
        server = ""

        currentAccount = nil
        isAuthenticated = false
    }
}
