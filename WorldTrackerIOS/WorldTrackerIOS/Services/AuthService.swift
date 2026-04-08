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
    
    /// Permanently delete the current user's account and all associated data
    /// This is a destructive operation that cannot be undone
    ///
    /// The deletion process follows these steps:
    /// 1. Reauthenticate the user with their current password (required by Firebase)
    /// 2. Delete all visit documents from Firestore
    /// 3. Delete the Firebase Authentication account
    ///
    /// - Parameter currentPassword: The user's current password for reauthentication
    /// - Throws: Authentication errors, network errors, or Firestore errors
    /// - Note: If any step fails, the process stops and throws an error. The auth state listener
    ///         will automatically trigger sign-out cleanup if the account is successfully deleted.
    func deleteAccount(currentPassword: String) async throws {
        // Step 1: Reauthenticate user (required by Firebase for account deletion)
        // This ensures the user is who they claim to be and refreshes their session token
        try await reauthenticate(currentPassword: currentPassword)
        
        // Step 2: Delete all Firestore visit documents for this user
        // Do this before deleting the auth account so we still have valid credentials
        let firestoreRepository = FirestoreVisitRepository()
        try await firestoreRepository.deleteAllUserVisits()
        
        // Step 3: Delete the Firebase Auth account
        // This is the final, irreversible step
        guard let user = Auth.auth().currentUser else {
            throw NSError(
                domain: "AuthService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "User session expired during account deletion"]
            )
        }
        
        try await user.delete()
        
        // Note: No need to call signOut() or clear local data here
        // The auth state listener will detect the account deletion and trigger
        // the sign-out flow automatically via authState change to .signedOut
    }
}
enum AuthState {
    case unknown
    case signedIn
    case signedOut
}

