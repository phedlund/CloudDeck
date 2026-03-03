//
//  SettingsView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//

#if !os(macOS)
import MessageUI
#endif
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(DeckAPI.self) private var deckAPI

    @Query private var ocsVersions: [OCSVersion]
    @Query private var decks: [Deck]

    @State private var isShowingMailView = false

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
                        let backgroundActor = DeckModelActor(modelContainer: modelContext.container)
                        Task {
                            try? await backgroundActor.reset()
                        }
                    } label: {
                        Label("Log Out", systemImage: "arrow.right.square")
                    }
                } header: {
                    Text("Actions")
                } footer: {
                    Text("This will remove your account from this device. Your data on the server will not be affected.")
                }
#if !os(macOS)
            Section {
                Button {
                    sendMail()
                } label: {
                    Label("Contact", systemImage: "mail")
                }
                Link(destination: URL(string: Constants.website)!) {
                    Label("Web Site", systemImage: "link")
                }
                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Label("Acknowledgements...", systemImage: "hand.thumbsup")

                }
            } header: {
                Text("Support")
            }
            .buttonStyle(.plain)
#endif

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
        .sheet(isPresented: $isShowingMailView) {
#if !os(macOS)
                MailComposeView(recipients: [Constants.email],
                                subject: Constants.subject,
                                message: Constants.message,
                                attachment: nil) {
                    // Did finish action
                }
#else
                EmptyView()
#endif

        }
    }

#if !os(macOS)
    private func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            isShowingMailView = true
        } else {
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = Constants.email
            components.queryItems = [URLQueryItem(name: "subject", value: Constants.subject),
                                     URLQueryItem(name: "body", value: Constants.message)]
            if let mailURL = components.url {
                openURL(mailURL)
            }
        }
    }
#endif

}

#Preview {
    SettingsView()
}
