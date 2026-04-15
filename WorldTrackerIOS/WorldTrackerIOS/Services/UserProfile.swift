//
//  UserProfile.swift
//  WorldTrackerIOS
//
//  Created by seren on 14.04.2026.
//

import Foundation

/// Represents a user's public profile for travel comparison
/// Stored at: users/{userId}/profile
struct UserProfile: Codable, Identifiable, Equatable {
    /// Firebase Auth user ID
    let id: String
    
    /// User's email address (for lookup)
    let email: String
    
    /// Privacy control: whether this user's travel data can be compared by others
    /// Default: false (private)
    var allowComparison: Bool
    
    /// When this profile was created
    let createdAt: Date
    
    /// When the profile was last updated
    var updatedAt: Date
    
    init(userId: String, email: String, allowComparison: Bool = false) {
        self.id = userId
        self.email = email
        self.allowComparison = allowComparison
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    /// Internal initializer for recreating profiles from Firestore with all fields
    init(userId: String, email: String, allowComparison: Bool, createdAt: Date, updatedAt: Date) {
        self.id = userId
        self.email = email
        self.allowComparison = allowComparison
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
