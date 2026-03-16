//
//  SyncService.swift
//  WorldTrackerIOS
//
//  Created by seren on 11.03.2026.
//

import Foundation

@MainActor
final class SyncService {
    private let localRepository: SwiftDataVisitRepository
    private let cloudRepository: FirestoreVisitRepository
    private let networkMonitor: NetworkMonitor
    
    private var isSyncing = false
    private(set) var lastSyncDate: Date?
    
    // Retry configuration
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0

    init(
        localRepository: SwiftDataVisitRepository,
        cloudRepository: FirestoreVisitRepository,
        networkMonitor: NetworkMonitor? = nil
    ) {
        self.localRepository = localRepository
        self.cloudRepository = cloudRepository
        self.networkMonitor = networkMonitor ?? .shared
    }

    func syncVisits(withRetry: Bool = true) async throws {
        print("🌐 Network status check: isConnected = \(networkMonitor.isConnected)")
        
        // Prevent concurrent syncs
        guard !isSyncing else {
            print("⚠️ Sync already in progress, skipping")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        print("🔄 Starting sync...")
        
        var lastError: Error?
        let attempts = withRetry ? maxRetries : 1
        
        for attempt in 1...attempts {
            do {
                try await performSync()
                lastSyncDate = Date()
                print("✅ Sync complete on attempt \(attempt)")
                return
            } catch let error as SyncError where error == .noConnection {
                // Don't retry if no connection
                throw error
            } catch {
                lastError = error
                print("⚠️ Sync attempt \(attempt) failed: \(error)")
                
                // If we have more attempts, wait before retrying
                if attempt < attempts {
                    print("⏳ Retrying in \(retryDelay) seconds...")
                    try await Task.sleep(for: .seconds(retryDelay))
                    // Removed network check - let the actual sync attempt determine if there's a connection
                }
            }
        }
        
        // All retries failed
        if let error = lastError {
            print("❌ Sync failed after \(attempts) attempts")
            throw SyncError.syncFailed(underlying: error, attempts: attempts)
        }
    }
    
    
    private func performSync() async throws {
        do {
            let localVisits = try localRepository.allVisits()
            let cloudVisits = try await cloudRepository.allVisits()

            let localById = Dictionary(uniqueKeysWithValues: localVisits.map { ($0.countryId, $0) })
            let cloudById = Dictionary(uniqueKeysWithValues: cloudVisits.map { ($0.countryId, $0) })

            let allCountryIDs = Set(localById.keys).union(cloudById.keys)

            var syncedCount = 0
            var errorCount = 0
            
            for countryId in allCountryIDs {
                let localVisit = localById[countryId]
                let cloudVisit = cloudById[countryId]

                do {
                    switch (localVisit, cloudVisit) {
                    case let (local?, cloud?):
                        // Both exist - use most recent
                        if local.updatedAt > cloud.updatedAt {
                            try await pushToCloud(local)
                            syncedCount += 1
                        } else if cloud.updatedAt > local.updatedAt {
                            try saveToLocal(cloud)
                            syncedCount += 1
                        }
                        // if equal, do nothing

                    case let (local?, nil):
                        // Only local - push to cloud
                        try await pushToCloud(local)
                    syncedCount += 1

                case let (nil, cloud?):
                    // Only cloud - save to local
                    try saveToLocal(cloud)
                    syncedCount += 1

                case (nil, nil):
                    break
                }
            } catch {
                print("⚠️ Failed to sync country \(countryId): \(error)")
                errorCount += 1
                // Continue with other countries
            }
        }
            
            print("✅ Sync complete: \(syncedCount) synced, \(errorCount) errors")
            
            // If there were any errors, throw an aggregate error
            if errorCount > 0 {
                throw SyncError.partialFailure(syncedCount: syncedCount, failedCount: errorCount)
            }
        } catch {
            // Check if it's a network error
            let nsError = error as NSError
            let errorDescription = error.localizedDescription.lowercased()
            
            print("🔍 Error details - Domain: \(nsError.domain), Code: \(nsError.code)")
            print("🔍 Error description: \(error.localizedDescription)")
            print("🔍 NetworkMonitor.isConnected: \(networkMonitor.isConnected)")
            
            // Check if it's our custom offline error
            if let repoError = error as? FirestoreVisitRepositoryError, repoError == .offline {
                print("❌ Firestore offline error detected (from cache check)")
                throw SyncError.noConnection
            }
            
            // Common network error codes and domains
            let isNetworkError = nsError.domain == NSURLErrorDomain ||
                                nsError.code == NSURLErrorNotConnectedToInternet ||
                                nsError.code == NSURLErrorNetworkConnectionLost ||
                                nsError.code == NSURLErrorTimedOut ||
                                nsError.code == NSURLErrorCannotConnectToHost ||
                                nsError.code == NSURLErrorCannotFindHost ||
                                (nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 14) || // Firestore unavailable
                                (nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7) ||  // Permission denied (often when offline)
                                errorDescription.contains("network") ||
                                errorDescription.contains("offline") ||
                                errorDescription.contains("internet") ||
                                errorDescription.contains("connection") ||
                                !networkMonitor.isConnected
            
            if isNetworkError {
                print("❌ Network error detected: \(error)")
                throw SyncError.noConnection
            } else {
                print("❌ Non-network error detected: \(error)")
                // Re-throw other errors
                throw error
            }
        }
    }

    private func pushToCloud(_ visit: Visit) async throws {
        try await cloudRepository.setVisited(
            visit.countryId,
            isVisited: visit.isVisited,
            visitedDate: visit.visitedDate,
            notes: visit.notes
        )
    }

    private func saveToLocal(_ visit: Visit) throws {
        try localRepository.upsert(visit)
    }
}

enum SyncError: LocalizedError, Equatable {
    case noConnection
    case syncFailed(underlying: Error, attempts: Int)
    case partialFailure(syncedCount: Int, failedCount: Int)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .syncFailed(let error, let attempts):
            return "Sync failed after \(attempts) attempt(s): \(error.localizedDescription)"
        case .partialFailure(let synced, let failed):
            return "Partial sync: \(synced) succeeded, \(failed) failed"
        }
    }
    
    static func == (lhs: SyncError, rhs: SyncError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection):
            return true
        case let (.syncFailed(_, attempts1), .syncFailed(_, attempts2)):
            return attempts1 == attempts2
        case let (.partialFailure(s1, f1), .partialFailure(s2, f2)):
            return s1 == s2 && f1 == f2
        default:
            return false
        }
    }
}

