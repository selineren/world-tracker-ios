//
//  VisitEntity.swift
//  WorldTrackerIOS
//
//  Created by seren on 2.03.2026.
//

import Foundation
import SwiftData

@Model
final class VisitEntity {
    @Attribute(.unique) var countryId: String
    var isVisited: Bool
    var visitedDate: Date?
    var notes: String

    init(countryId: String, isVisited: Bool = false, visitedDate: Date? = nil, notes: String = "") {
        self.countryId = countryId
        self.isVisited = isVisited
        self.visitedDate = visitedDate
        self.notes = notes
    }
}
