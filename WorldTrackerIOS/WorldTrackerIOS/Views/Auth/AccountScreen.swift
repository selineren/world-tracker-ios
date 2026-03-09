//
//  AccountScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 9.03.2026.
//

import SwiftUI

struct AccountScreen: View {
    @EnvironmentObject private var authService: AuthService
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    Text(authService.userEmail)
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        do {
                            try authService.signOut()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
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
}
