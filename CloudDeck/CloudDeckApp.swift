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

    private let container: ModelContainer
    private let modelActor: DeckModelActor
    private let deckAPI: DeckAPI

    init() {
        do {
            container = try ModelContainer(for: schema)
            self.modelActor = DeckModelActor(modelContainer: container)
            self.deckAPI = DeckAPI(modelContainer: container)
        } catch {
            fatalError("Failed to create container")
        }
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environment(authManager)
                    .environment(deckAPI)
            } else {
                LoginView()
                    .environment(authManager)
            }
        }
        .modelContainer(container)
    }
}

#Preview("Authenticated") {
    // Provide an in-memory ModelContainer for previews to avoid ambiguity
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: configuration)

    let authManager = AuthenticationManager()
    authManager.isAuthenticated = true

    let deckAPI = DeckAPI(modelContainer: container)

    return ContentView()
        .environment(authManager)
        .environment(deckAPI)
        .modelContainer(container)
}

#Preview("Login") {
    let authManager = AuthenticationManager()
    authManager.isAuthenticated = false
    return LoginView()
        .environment(authManager)
}

