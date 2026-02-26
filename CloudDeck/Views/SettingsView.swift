//
//  SettingsView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(DeckAPI.self) private var deckAPI

    var body: some View {
        NavigationStack {
            List {
                if let account = authManager.currentAccount() {
                    Section {
                        LabeledContent("Server", value: account.serverURL)
                        LabeledContent("Username", value: account.username)
                    } header: {
                        Text("Account")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Label("Log Out", systemImage: "arrow.right.square")
                    }
                } header: {
                    Text("Actions")
                } footer: {
                    Text("This will remove your account from this device. Your data on the server will not be affected.")
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            try? await deckAPI.ncVersion()
        }
    }
}

#Preview {
    SettingsView()
}
