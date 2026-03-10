//
//  FirestoreVisitRepositoryError.swift
//  WorldTrackerIOS
//
//  Created by seren on 10.03.2026.
//

import Foundation

enum FirestoreVisitRepositoryError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case invalidData
    case permissionDenied
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated."
        case .documentNotFound:
            return "Document not found."
        case .invalidData:
            return "Firestore document contains invalid data."
        case .permissionDenied:
            return "Permission denied."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
