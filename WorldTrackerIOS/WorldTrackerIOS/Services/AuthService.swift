//
//  AuthService.swift
//  WorldTrackerIOS
//
//  Created by seren on 9.03.2026.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var user: User?

    var userEmail: String {
        user?.email ?? "Unknown user"
    }
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        user = Auth.auth().currentUser

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    var isSignedIn: Bool {
        user != nil
    }

    func signUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
