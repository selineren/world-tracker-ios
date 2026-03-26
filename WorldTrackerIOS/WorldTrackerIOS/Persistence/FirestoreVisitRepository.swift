//
//  FirestoreVisitRepository.swift
//  WorldTrackerIOS
//
//  Created by seren on 10.03.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

final class FirestoreVisitRepository {
    private let db = Firestore.firestore()

    // MARK: - Public API

    func visit(for countryId: String) async throws -> Visit {
        let doc = try await getVisitDocument(countryId: countryId)

        guard let data = doc.data() else {
            throw FirestoreVisitRepositoryError.documentNotFound
        }

        return try mapVisit(countryId: countryId, data: data)
    }

    func allVisits() async throws -> [Visit] {
        let userID = try requireUserID()

        let snapshot = try await getDocuments(
            from: db.collection("users")
                .document(userID)
                .collection("visits")
        )

        return try snapshot.documents.map { document in
            try mapVisit(countryId: document.documentID, data: document.data())
        }
    }

    func setVisited(_ countryId: String, isVisited: Bool, visitedDate: Date?, notes: String) async throws {
        let userID = try requireUserID()

        let data: [String: Any] = [
            "isVisited": isVisited,
            "visitedDate": visitedDate as Any,
            "notes": notes,
            "updatedAt": Timestamp(date: Date())
        ]

        try await setData(
            data,
            for: db.collection("users")
                .document(userID)
                .collection("visits")
                .document(countryId)
        )
    }

    func updateNotes(_ countryId: String, notes: String) async throws {
        let userID = try requireUserID()

        let ref = db.collection("users")
            .document(userID)
            .collection("visits")
            .document(countryId)

        let data: [String: Any] = [
            "notes": notes,
            "updatedAt": Timestamp(date: Date())
        ]

        try await updateData(data, for: ref)
    }
    
    func addPhoto(_ countryId: String, photo: VisitPhoto) async throws {
        let userID = try requireUserID()
        let ref = db.collection("users")
            .document(userID)
            .collection("visits")
            .document(countryId)
        
        // Fetch current visit to get existing photos
        let visit = try await self.visit(for: countryId)
        var photos = visit.photos
        photos.append(photo)
        
        // Encode photos as Base64 string for Firestore
        let photosBase64 = try encodePhotosToBase64(photos)
        
        let data: [String: Any] = [
            "photos": photosBase64,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await updateData(data, for: ref)
    }
    
    func removePhoto(_ countryId: String, photoId: UUID) async throws {
        let userID = try requireUserID()
        let ref = db.collection("users")
            .document(userID)
            .collection("visits")
            .document(countryId)
        
        // Fetch current visit to get existing photos
        let visit = try await self.visit(for: countryId)
        var photos = visit.photos
        photos.removeAll { $0.id == photoId }
        
        // Encode photos as Base64 string for Firestore
        let photosBase64 = try encodePhotosToBase64(photos)
        
        let data: [String: Any] = [
            "photos": photosBase64,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await updateData(data, for: ref)
    }
    
    func updatePhotoCaption(_ countryId: String, photoId: UUID, caption: String) async throws {
        let userID = try requireUserID()
        let ref = db.collection("users")
            .document(userID)
            .collection("visits")
            .document(countryId)
        
        // Fetch current visit to get existing photos
        let visit = try await self.visit(for: countryId)
        var photos = visit.photos
        
        if let index = photos.firstIndex(where: { $0.id == photoId }) {
            photos[index].caption = caption
            
            // Encode photos as Base64 string for Firestore
            let photosBase64 = try encodePhotosToBase64(photos)
            
            let data: [String: Any] = [
                "photos": photosBase64,
                "updatedAt": Timestamp(date: Date())
            ]
            
            try await updateData(data, for: ref)
        }
    }

    func deleteVisit(_ countryId: String) async throws {
        let userID = try requireUserID()

        try await deleteDocument(
            db.collection("users")
                .document(userID)
                .collection("visits")
                .document(countryId)
        )
    }

    // MARK: - Helpers

    private func requireUserID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreVisitRepositoryError.notAuthenticated
        }
        return uid
    }

    private func getVisitDocument(countryId: String) async throws -> DocumentSnapshot {
        let userID = try requireUserID()

        return try await getDocument(
            from: db.collection("users")
                .document(userID)
                .collection("visits")
                .document(countryId)
        )
    }

    private func mapVisit(countryId: String, data: [String: Any]) throws -> Visit {
        guard let isVisited = data["isVisited"] as? Bool else {
            throw FirestoreVisitRepositoryError.invalidData
        }

        let notes = data["notes"] as? String ?? ""

        let visitedDate: Date?
        if let timestamp = data["visitedDate"] as? Timestamp {
            visitedDate = timestamp.dateValue()
        } else {
            visitedDate = nil
        }
        
        let updatedAt: Date
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            throw FirestoreVisitRepositoryError.invalidData
        }
        
        // Decode photos from Base64-encoded JSON array
        let photos: [VisitPhoto]
        if let photosBase64 = data["photos"] as? String,
           let photosData = Data(base64Encoded: photosBase64) {
            photos = (try? JSONDecoder().decode([VisitPhoto].self, from: photosData)) ?? []
        } else {
            photos = []
        }
        
        // Ensure visited countries have a date - if missing, use updatedAt as best guess
        let finalVisitedDate: Date?
        if isVisited {
            finalVisitedDate = visitedDate ?? updatedAt
        } else {
            finalVisitedDate = nil
        }

        return Visit(
            countryId: countryId,
            isVisited: isVisited,
            visitedDate: finalVisitedDate,
            notes: notes,
            photos: photos,
            updatedAt: updatedAt
        )
    }

    // MARK: - Async wrappers

    private func getDocument(from ref: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            // Use source: .server to force network fetch, not cache
            ref.getDocument(source: .server) { snapshot, error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: FirestoreVisitRepositoryError.documentNotFound)
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }
    }

    private func getDocuments(from ref: CollectionReference) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { continuation in
            // Use source: .server to force network fetch, not cache
            ref.getDocuments(source: .server) { snapshot, error in
                if let error {
                    print("🔥 Firestore error: \(error)")
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let snapshot else {
                    print("🔥 Firestore: No snapshot returned")
                    continuation.resume(throwing: FirestoreVisitRepositoryError.invalidData)
                    return
                }
                
                // Check if this data came from cache despite requesting server
                print("🔥 Firestore snapshot: \(snapshot.documents.count) docs, metadata.isFromCache: \(snapshot.metadata.isFromCache)")
                
                // If we requested server but got cache, and we're offline, throw error
                if snapshot.metadata.isFromCache {
                    print("⚠️ Received cached data when server was requested - treating as offline")
                    continuation.resume(throwing: FirestoreVisitRepositoryError.offline)
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
                    continuation.resume(throwing: self.mapError(error))
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
                    continuation.resume(throwing: self.mapError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteDocument(_ ref: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.delete { error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func mapError(_ error: Error) -> FirestoreVisitRepositoryError {
        let nsError = error as NSError

        // 7 is permission denied in gRPC / Firestore permission failures
        if nsError.code == 7 {
            return .permissionDenied
        }

        return .unknown(error)
    }
    
    // MARK: - Photo encoding
    
    private func encodePhotosToBase64(_ photos: [VisitPhoto]) throws -> String {
        let jsonData = try JSONEncoder().encode(photos)
        return jsonData.base64EncodedString()
    }
}
