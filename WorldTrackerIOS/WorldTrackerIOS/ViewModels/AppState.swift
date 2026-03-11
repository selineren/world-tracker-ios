//
//  AppState.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var visits: [String: Visit] = [:]
    @Published private(set) var visitedCountryIDs: Set<String> = []

    private let repository: VisitRepository
    private let syncService: SyncService?

    init(repository: VisitRepository, syncService: SyncService? = nil) {
        self.repository = repository
        self.syncService = syncService
        loadFromPersistence()
    }

    private func loadFromPersistence() {
        do {
            let stored = try repository.allVisits()
            self.visits = Dictionary(uniqueKeysWithValues: stored.map { ($0.countryId, $0) })
            self.visitedCountryIDs = Set(stored.filter { $0.isVisited }.map { $0.countryId })
        } catch {
            print("⚠️ Failed to load visits from SwiftData: \(error)")
            self.visits = [:]
            self.visitedCountryIDs = []
        }
    }

    func refreshFromPersistence() {
        loadFromPersistence()
    }
    
    func syncWithCloud() async {
        guard let syncService else { return }

        do {
            try await syncService.syncVisits()
            loadFromPersistence()
        } catch {
            print("⚠️ Sync failed: \(error)")
        }
    }
    
    func visit(for countryId: String) -> Visit {
        visits[countryId] ?? Visit(countryId: countryId, isVisited: false, visitedDate: nil, notes: "", updatedAt: Date())
    }

    func isVisited(_ countryId: String) -> Bool {
        visit(for: countryId).isVisited
    }

    func setVisited(_ countryId: String, isVisited: Bool, visitedDate: Date? = nil) {
        var v = visit(for: countryId)
        v.isVisited = isVisited

        if isVisited {
            v.visitedDate = visitedDate ?? v.visitedDate ?? Date()
        } else {
            v.visitedDate = nil
        }
        v.updatedAt = Date()

        // Update UI immediately
        visits[countryId] = v
        if isVisited {
            visitedCountryIDs.insert(countryId)
        } else {
            visitedCountryIDs.remove(countryId)
        }

        // Persist
        do {
            try repository.setVisited(countryId, isVisited: isVisited, visitedDate: v.visitedDate)
            Task {
                await syncWithCloud()
            }
        } catch {
            print("⚠️ Failed to persist setVisited: \(error)")
        }
    }

    func updateNotes(_ countryId: String, notes: String) {
        var v = visit(for: countryId)
        v.notes = notes
        v.updatedAt = Date()
        visits[countryId] = v

        do {
            try repository.updateNotes(countryId, notes: notes)
            Task {
                await syncWithCloud()
            }
        } catch {
            print("⚠️ Failed to persist updateNotes: \(error)")
        }
    }

    var visitedCount: Int {
        visits.values.filter { $0.isVisited }.count
    }
    
    func clearLocalState() {
        visits = [:]
        visitedCountryIDs = []
    }
    
    func clearLocalDataAfterSignOut() {
        do {
            if let localRepository = repository as? SwiftDataVisitRepository {
                try localRepository.deleteAllVisits()
            }
            clearLocalState()
        } catch {
            print("⚠️ Failed to clear local data after sign out: \(error)")
        }
    }
}
