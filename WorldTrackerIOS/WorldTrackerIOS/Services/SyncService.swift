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
    
    private var isSyncing = false
    private var lastSyncDate: Date?

    init(
        localRepository: SwiftDataVisitRepository,
        cloudRepository: FirestoreVisitRepository
    ) {
        self.localRepository = localRepository
        self.cloudRepository = cloudRepository
    }

    func syncVisits() async throws {
        // Prevent concurrent syncs
        guard !isSyncing else {
            print("⚠️ Sync already in progress, skipping")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        print("🔄 Starting sync...")
        
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
            
            lastSyncDate = Date()
            print("✅ Sync complete: \(syncedCount) synced, \(errorCount) errors")
            
            // If there were any errors, throw an aggregate error
            if errorCount > 0 {
                throw SyncError.partialFailure(syncedCount: syncedCount, failedCount: errorCount)
            }
        } catch let error as SyncError {
            throw error
        } catch {
            print("❌ Sync failed: \(error)")
            throw SyncError.syncFailed(underlying: error)
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
enum SyncError: LocalizedError {
    case syncFailed(underlying: Error)
    case partialFailure(syncedCount: Int, failedCount: Int)
    
    var errorDescription: String? {
        switch self {
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .partialFailure(let synced, let failed):
            return "Partial sync: \(synced) succeeded, \(failed) failed"
        }
    }
}

