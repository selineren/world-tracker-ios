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

    init(repository: VisitRepository) {
        self.repository = repository
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

    func visit(for countryId: String) -> Visit {
        visits[countryId] ?? Visit(countryId: countryId, isVisited: false, visitedDate: nil, notes: "")
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
        } catch {
            print("⚠️ Failed to persist setVisited: \(error)")
        }
    }

    func updateNotes(_ countryId: String, notes: String) {
        var v = visit(for: countryId)
        v.notes = notes
        visits[countryId] = v

        do {
            try repository.updateNotes(countryId, notes: notes)
        } catch {
            print("⚠️ Failed to persist updateNotes: \(error)")
        }
    }

    var visitedCount: Int {
        visits.values.filter { $0.isVisited }.count
    }
}
