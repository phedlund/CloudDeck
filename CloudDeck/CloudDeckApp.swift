//
//  CloudDeckApp.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/27/26.
//

import SwiftUI
import SwiftData

@main
struct CloudDeckApp: App {
    @State private var authManager = AuthenticationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainAppView()
                    .environment(authManager)
            } else {
                NextcloudLoginView()
                    .environment(authManager)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Authentication Manager using @Observable

@Observable
@MainActor
class AuthenticationManager {
    var isAuthenticated = false
    var currentAccount: Account?

    init() {
        checkAuthentication()
    }

    func checkAuthentication() {
        // Check Keychain for stored credentials
        if let serverURL = UserDefaults.standard.string(forKey: "serverURL"),
           let username = UserDefaults.standard.string(forKey: "username"),
           let password = KeychainHelper.get(for: "\(serverURL)_\(username)") {

            currentAccount = Account(
                serverURL: serverURL,
                username: username,
                appPassword: password
            )
            isAuthenticated = true
        }
    }

    func login(credentials: NextcloudCredentials) {
        // Save credentials
        KeychainHelper.save(
            credentials.appPassword,
            for: "\(credentials.server)_\(credentials.loginName)"
        )

        UserDefaults.standard.set(credentials.server, forKey: "serverURL")
        UserDefaults.standard.set(credentials.loginName, forKey: "username")

        currentAccount = Account(
            serverURL: credentials.server,
            username: credentials.loginName,
            appPassword: credentials.appPassword
        )

        isAuthenticated = true
    }

    func logout() {
        guard let account = currentAccount else { return }

        // Delete from Keychain
        KeychainHelper.delete(for: "\(account.serverURL)_\(account.username)")

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "serverURL")
        UserDefaults.standard.removeObject(forKey: "username")

        currentAccount = nil
        isAuthenticated = false
    }
}

// MARK: - Account Model

struct Account {
    let serverURL: String
    let username: String
    let appPassword: String
}

// MARK: - Main App View

struct MainAppView: View {
    @Environment(AuthenticationManager.self) private var authManager

    var body: some View {
        TabView {
            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct FilesView: View {
    @Environment(AuthenticationManager.self) private var authManager

    var body: some View {
        NavigationStack {
            List {
                if let account = authManager.currentAccount {
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.username)
                                    .font(.headline)
                                Text(account.serverURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } header: {
                        Text("Account")
                    }
                }

                Section {
                    Label("Documents", systemImage: "doc.fill")
                    Label("Photos", systemImage: "photo.fill")
                    Label("Videos", systemImage: "video.fill")
                } header: {
                    Text("Your Files")
                }
            }
            .navigationTitle("Files")
        }
    }
}

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager

    var body: some View {
        NavigationStack {
            List {
                if let account = authManager.currentAccount {
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
    }
}

//#Preview {
//    CloudDeckApp()
//}
