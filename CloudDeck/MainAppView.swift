//
//  MainAppView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//


import SwiftUI
import SwiftData

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