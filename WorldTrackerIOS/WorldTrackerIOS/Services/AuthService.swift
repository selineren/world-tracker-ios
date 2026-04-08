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
    @Published private(set) var authState: AuthState = .unknown

    var userEmail: String {
        user?.email ?? "Unknown user"
    }
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        user = Auth.auth().currentUser
        authState = user != nil ? .signedIn : .signedOut

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            
            let previousUser = self.user
            self.user = user
            
            // Detect actual state changes
            if previousUser?.uid != user?.uid {
                if user != nil {
                    self.authState = .signedIn
                } else {
                    self.authState = .signedOut
                }
            }
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

    /// Reauthenticate the current user with their password
    /// Required by Firebase before sensitive operations like password changes
    func reauthenticate(currentPassword: String) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            throw NSError(
                domain: "AuthService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"]
            )
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
    }

    /// Update the current user's password to a new value
    /// Note: User must be recently authenticated (call reauthenticate first)
    func updatePassword(newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(
                domain: "AuthService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "User session expired"]
            )
        }
        
        try await user.updatePassword(to: newPassword)
    }
}
enum AuthState {
    case unknown
    case signedIn
    case signedOut
}

