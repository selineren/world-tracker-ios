//
//  StatsScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI

struct StatsScreen: View {
    @EnvironmentObject private var appState: AppState
    private let countries = MockCountryService().loadCountries()

    // MARK: - Computed stats

    private var visitedVisits: [Visit] {
        appState.visits.values
            .filter { $0.isVisited }
    }

    private var totalCountriesCount: Int {
        countries.count
    }

    private var visitedCountriesCount: Int {
        visitedVisits.count
    }

    private var visitedCountries: [Country] {
        let visitedIDs = Set(visitedVisits.map { $0.countryId })
        return countries.filter { visitedIDs.contains($0.id) }
    }

    private var visitedByContinent: [(continent: Continent, visited: Int, total: Int)] {
        let grouped = Dictionary(grouping: countries, by: { $0.continent })

        return Continent.allCases.map { continent in
            let all = grouped[continent] ?? []
            let visitedIDs = Set(visitedVisits.map { $0.countryId })
            let visited = all.filter { visitedIDs.contains($0.id) }.count
            return (continent: continent, visited: visited, total: all.count)
        }
        .filter { $0.total > 0 }
    }

    private var recentVisits: [(country: Country, date: Date?)] {
        let byId = Dictionary(uniqueKeysWithValues: countries.map { ($0.id, $0) })

        return visitedVisits
            .compactMap { visit in
                guard let country = byId[visit.countryId] else { return nil }
                return (country: country, date: visit.visitedDate)
            }
            .sorted {
                // visits with date first, newest first
                switch ($0.date, $1.date) {
                case let (d0?, d1?):
                    return d0 > d1
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    return $0.country.name < $1.country.name
                }
            }
    }

    // MARK: - UI

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    StatRow(title: "Visited countries", value: "\(visitedCountriesCount) / \(totalCountriesCount)")

                    if !visitedCountries.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(visitedCountries.prefix(8)) { country in
                                    Text("\(country.flagEmoji) \(country.name)")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.thinMaterial)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Visited by continent") {
                    ForEach(visitedByContinent, id: \.continent.id) { item in
                        HStack {
                            Text(item.continent.displayName)
                            Spacer()
                            Text("\(item.visited) / \(item.total)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Recent visits") {
                    if recentVisits.isEmpty {
                        Text("No visits yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentVisits.prefix(10), id: \.country.id) { item in
                            NavigationLink {
                                CountryDetailScreen(country: item.country)
                            } label: {
                                HStack(spacing: 12) {
                                    Text(item.country.flagEmoji)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.country.name)
                                        Text(item.country.continent.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(formattedDate(item.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stats")
            .listStyle(.insetGrouped)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
