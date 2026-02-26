//
//  SettingsView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(DeckAPI.self) private var deckAPI

    @Query private var ocsVersions: [OCSVersion]
    @Query private var decks: [Deck]

    var ncVersion: String {
        ocsVersions.first?.string ?? "unknown version"
    }

    var deckVersion: String {
        decks.first?.version ?? "unknown version"
    }

    var body: some View {
        NavigationStack {
            Form {
                if let account = authManager.currentAccount() {
                    Section {
                        LabeledContent("Server", value: account.serverURL)
                        LabeledContent("Username", value: account.username)
                    } header: {
                        Text("Account")
                    } footer: {
                        Text("Using Deck \(deckVersion) on Nextcloud \(ncVersion)")
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            try? await deckAPI.capabilities()
        }
    }
}

#Preview {
    SettingsView()
}
