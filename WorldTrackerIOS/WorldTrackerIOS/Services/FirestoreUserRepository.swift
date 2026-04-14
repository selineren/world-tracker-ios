//
//  FirestoreUserRepository.swift
//  WorldTrackerIOS
//
//  Created by seren on 14.04.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Repository for managing user profiles in Firestore
/// Document path: users/{userId}/profile
final class FirestoreUserRepository {
    private let db = Firestore.firestore()
    
    // MARK: - Current User Profile Operations
    
    /// Create or update the current user's profile
    /// - Parameter profile: The profile to save
    /// - Throws: FirestoreUserRepositoryError if not authenticated or save fails
    func createOrUpdateProfile(_ profile: UserProfile) async throws {
        let userID = try requireUserID()
        
        // Ensure the profile ID matches the current user
        guard profile.id == userID else {
            throw FirestoreUserRepositoryError.invalidProfileData
        }
        
        let data: [String: Any] = [
            "email": profile.email,
            "allowComparison": profile.allowComparison,
            "createdAt": Timestamp(date: profile.createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await setData(data, for: profileDocument())
        
        #if DEBUG
        print("✅ Profile saved for user: \(userID)")
        #endif
    }
    
    /// Fetch the current user's profile
    /// - Returns: UserProfile if it exists, nil otherwise
    /// - Throws: FirestoreUserRepositoryError if not authenticated or fetch fails
    func getCurrentUserProfile() async throws -> UserProfile? {
        let userID = try requireUserID()
        let doc = try await getDocument(from: profileDocument())
        
        guard doc.exists, let data = doc.data() else {
            return nil
        }
        
        return try mapProfile(userId: userID, data: data)
    }
    
    /// Update the allowComparison setting for the current user
    /// - Parameter allowComparison: Whether to allow travel data comparison
    /// - Throws: FirestoreUserRepositoryError if not authenticated or update fails
    func updateComparisonSetting(allowComparison: Bool) async throws {
        let data: [String: Any] = [
            "allowComparison": allowComparison,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await updateData(data, for: profileDocument())
        
        #if DEBUG
        print("✅ Updated allowComparison to: \(allowComparison)")
        #endif
    }
    
    // MARK: - Private Helpers
    
    /// Get the current authenticated user's ID
    private func requireUserID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreUserRepositoryError.notAuthenticated
        }
        return uid
    }
    
    /// Get reference to the current user's profile document
    private func profileDocument() throws -> DocumentReference {
        let userID = try requireUserID()
        return db.collection("users")
            .document(userID)
            .collection("profile")
            .document("data")
    }
    
    /// Map Firestore data to UserProfile model
    private func mapProfile(userId: String, data: [String: Any]) throws -> UserProfile {
        guard let email = data["email"] as? String else {
            throw FirestoreUserRepositoryError.invalidProfileData
        }
        
        let allowComparison = data["allowComparison"] as? Bool ?? false
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let updatedAt: Date
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }
        
        var profile = UserProfile(userId: userId, email: email, allowComparison: allowComparison)
        profile.updatedAt = updatedAt
        
        return profile
    }
    
    // MARK: - Async Wrappers
    
    private func getDocument(from ref: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            ref.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: FirestoreUserRepositoryError.unknown(error))
                    return
                }
                
                guard let snapshot else {
                    continuation.resume(throwing: FirestoreUserRepositoryError.documentNotFound)
                    return
                }
                
                continuation.resume(returning: snapshot)
            }
        }
    }
    
    private func setData(_ data: [String: Any], for ref: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.setData(data) { error in
                if let error {
                    continuation.resume(throwing: FirestoreUserRepositoryError.unknown(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func updateData(_ data: [String: Any], for ref: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateData(data) { error in
                if let error {
                    continuation.resume(throwing: FirestoreUserRepositoryError.unknown(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Errors

enum FirestoreUserRepositoryError: LocalizedError, Equatable {
    case notAuthenticated
    case documentNotFound
    case invalidProfileData
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated."
        case .documentNotFound:
            return "Profile document not found."
        case .invalidProfileData:
            return "Profile data is invalid or corrupted."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    static func == (lhs: FirestoreUserRepositoryError, rhs: FirestoreUserRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.documentNotFound, .documentNotFound),
             (.invalidProfileData, .invalidProfileData):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
