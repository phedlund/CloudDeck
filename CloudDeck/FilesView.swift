//
//  FilesView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/1/26.
//


import SwiftUI
import SwiftData

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