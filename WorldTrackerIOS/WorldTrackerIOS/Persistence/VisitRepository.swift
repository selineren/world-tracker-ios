//
//  VisitRepository.swift
//  WorldTrackerIOS
//
//  Created by seren on 2.03.2026.
//

import Foundation

protocol VisitRepository {
    func visit(for countryId: String) throws -> Visit
    func allVisits() throws -> [Visit]
    func setVisited(_ countryId: String, isVisited: Bool, visitedDate: Date?) throws
    func updateNotes(_ countryId: String, notes: String) throws
    func upsert(_ visit: Visit) throws
    func visitedCount() throws -> Int
}
