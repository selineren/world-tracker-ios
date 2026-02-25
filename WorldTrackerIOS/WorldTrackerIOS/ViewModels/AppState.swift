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
    /// Key = Country ISO code (Country.id)
    @Published var visits: [String: Visit] = [:]
    
    func visit(for countryId: String) -> Visit {
        visits[countryId] ?? Visit(countryId: countryId, isVisited: false, visitedDate: nil, notes: "")
    }
    
    func isVisited(_ countryId: String) -> Bool {
        visit(for: countryId).isVisited
    }
    
    func setVisited(_ countryId: String, isVisited: Bool) {
        var v = visit(for: countryId)
        v.isVisited = isVisited
        if isVisited && v.visitedDate == nil {
            v.visitedDate = Date()
        }
        if !isVisited {
            v.visitedDate = nil
            v.notes = ""
        }
        visits[countryId] = v
    }
    
    func updateNotes(_ countryId: String, notes: String) {
        var v = visit(for: countryId)
        v.notes = notes
        visits[countryId] = v
    }
    
    // MARK: - Stats
    
    var visitedCount: Int {
        visits.values.filter { $0.isVisited }.count
    }
}
