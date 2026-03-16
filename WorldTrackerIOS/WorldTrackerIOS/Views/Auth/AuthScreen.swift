//
//  AuthScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 9.03.2026.
//

import SwiftUI

struct AuthScreen: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                }

                Section {
                    Button(isCreatingAccount ? "Create account" : "Sign in") {
                        Task {
                            await submit()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty)

                    Button(isCreatingAccount ? "Already have an account? Sign in"
                                             : "Need an account? Sign up") {
                        isCreatingAccount.toggle()
                    }
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Account")
        }
    }

    private func submit() async {
        errorMessage = nil

        do {
            if isCreatingAccount {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }

            try await appState.syncWithCloud()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
