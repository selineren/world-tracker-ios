//
//  SwiftDataVisitRepository.swift
//  WorldTrackerIOS
//
//  Created by seren on 2.03.2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataVisitRepository: VisitRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func visit(for countryId: String) throws -> Visit {
        if let entity = try fetchEntity(countryId: countryId) {
            return Visit(
                countryId: entity.countryId,
                isVisited: entity.isVisited,
                visitedDate: entity.visitedDate,
                notes: entity.notes
            )
        }

        // default “not visited”
        return Visit(countryId: countryId, isVisited: false, visitedDate: nil, notes: "")
    }

    func setVisited(_ countryId: String, isVisited: Bool, visitedDate: Date?) throws {
        let entity = try fetchOrCreateEntity(countryId: countryId)

        entity.isVisited = isVisited

        if isVisited {
            // IMPORTANT: allow choosing date; if none provided, keep existing; if none exists, default today
            entity.visitedDate = visitedDate ?? entity.visitedDate ?? Date()
        } else {
            entity.visitedDate = nil
            // keep notes (better UX) — do NOT wipe them
        }

        try context.save()
    }

    func updateNotes(_ countryId: String, notes: String) throws {
        let entity = try fetchOrCreateEntity(countryId: countryId)
        entity.notes = notes
        try context.save()
    }

    func visitedCount() throws -> Int {
        let descriptor = FetchDescriptor<VisitEntity>(
            predicate: #Predicate { $0.isVisited == true }
        )
        return try context.fetchCount(descriptor)
    }

    // MARK: - Private helpers

    private func fetchEntity(countryId: String) throws -> VisitEntity? {
        let descriptor = FetchDescriptor<VisitEntity>(
            predicate: #Predicate { $0.countryId == countryId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchOrCreateEntity(countryId: String) throws -> VisitEntity {
        if let existing = try fetchEntity(countryId: countryId) {
            return existing
        }
        let created = VisitEntity(countryId: countryId)
        context.insert(created)
        return created
    }
}
