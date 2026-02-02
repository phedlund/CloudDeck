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
                DeckRootView()
                    .environment(authManager)
            } else {
                NextcloudLoginView()
                    .environment(authManager)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

//#Preview {
//    CloudDeckApp()
//}
