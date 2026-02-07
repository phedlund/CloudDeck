//
//  LoginView.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 1/30/26.
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(AuthenticationManager.self) private var authManager

    @State private var serverURL: String = ""
    @State private var authService = NextcloudAuthService()

    private let bgColor = Color.NC

    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image("NCLogo")
                        .font(.system(size: 60))

                    Text("Connect to Nextcloud")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(bgColor.accessibleTextColor)

                    Text("Enter your Nextcloud server address")
                        .font(.subheadline)
                        .foregroundStyle(bgColor.accessibleTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Server URL Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField(
                            text: $serverURL,
                            prompt: Text(verbatim: "https://cloud.example.com/")
                                .foregroundColor(bgColor.accessibleTextColor.opacity(0.5))
                        ) {
                            Text("Server Address", comment: "Label for text field.")
                        }
                        .foregroundStyle(bgColor.accessibleTextColor)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
#if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
#endif
                        .onSubmit {
                            doLogin()
                        }

                        Button {
                            doLogin()
                        } label: {
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(bgColor.accessibleTextColor)
#if os(macOS)
                        .buttonStyle(.plain)
#endif
                    }
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(bgColor.accessibleTextColor, lineWidth: 1)
                    )
                }
                .padding(.horizontal)

                // Error Message
                //                if let errorMessage = authModel.errorMessage {
                //                    Text(errorMessage)
                //                        .font(.caption)
                //                        .foregroundStyle(.red)
                //                        .padding(.horizontal)
                //                }

                Spacer()
            }
            .tint(bgColor.accessibleTextColor)
            .safeAreaPadding(.all)
            .onChange(of: authService.credentials) { oldValue, newValue in
                if let creds = newValue {
                    handleSuccessfulLogin(creds)
                }
            }
        }
    }

    private func doLogin() {
        Task {
            // Sanitize URL
            let sanitizationResult = URLSanitizer.sanitize(serverURL)

            switch sanitizationResult {
            case .success(let sanitizedURL):
                Task {
                    await authService.executeFullAuth(
                        serverURL: URL(string: sanitizedURL)!,
                        session: webAuthenticationSession
                    )
                }

            case .failure(let error):
                break
                //                                    loginService.errorMessage = error.localizedDescription
            }
        }
    }

    private func handleSuccessfulLogin(_ credentials: NextcloudCredentials) {
        // Save credentials securely (e.g., to Keychain)
        print("✅ Login successful!")
        print("Server: \(credentials.server)")
        print("Username: \(credentials.loginName)")
        print("App Password: \(credentials.appPassword)")
        authManager.login(credentials: credentials)
    }
}

#Preview {
    LoginView()
}
