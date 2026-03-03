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

    private let repository: VisitRepository

    init(repository: VisitRepository) {
        self.repository = repository
        loadFromPersistence()
    }

    private func loadFromPersistence() {
        do {
            let stored = try repository.allVisits()
            self.visits = Dictionary(uniqueKeysWithValues: stored.map { ($0.countryId, $0) })
        } catch {
            // In production you might log this; for now keep app usable
            print("⚠️ Failed to load visits from SwiftData: \(error)")
            self.visits = [:]
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
            // keep notes
        }

        // Update UI immediately
        visits[countryId] = v

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

        // Update UI immediately
        visits[countryId] = v

        // Persist
        do {
            try repository.updateNotes(countryId, notes: notes)
        } catch {
            print("⚠️ Failed to persist updateNotes: \(error)")
        }
    }

    // MARK: - Stats

    var visitedCount: Int {
        visits.values.filter { $0.isVisited }.count
    }
}
