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

    init(
        localRepository: SwiftDataVisitRepository,
        cloudRepository: FirestoreVisitRepository
    ) {
        self.localRepository = localRepository
        self.cloudRepository = cloudRepository
    }

    func syncVisits() async throws {
        let localVisits = try localRepository.allVisits()
        let cloudVisits = try await cloudRepository.allVisits()

        let localById = Dictionary(uniqueKeysWithValues: localVisits.map { ($0.countryId, $0) })
        let cloudById = Dictionary(uniqueKeysWithValues: cloudVisits.map { ($0.countryId, $0) })

        let allCountryIDs = Set(localById.keys).union(cloudById.keys)

        for countryId in allCountryIDs {
            let localVisit = localById[countryId]
            let cloudVisit = cloudById[countryId]

            switch (localVisit, cloudVisit) {
            case let (local?, cloud?):
                if local.updatedAt > cloud.updatedAt {
                    try await pushToCloud(local)
                } else if cloud.updatedAt > local.updatedAt {
                    try saveToLocal(cloud)
                }
                // if equal, do nothing

            case let (local?, nil):
                try await pushToCloud(local)

            case let (nil, cloud?):
                try saveToLocal(cloud)

            case (nil, nil):
                break
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
