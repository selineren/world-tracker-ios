//
//  StatsScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI
import Combine

struct StatsScreen: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = StatsViewModel()
    
    init() {
        print("🎨 StatsScreen initialized")
    }
    
    // MARK: - Computed stats
    
    private var visitedVisits: [Visit] {
        appState.visits.values
            .filter { $0.isVisited }
    }
    
    private var totalCountriesCount: Int {
        vm.countries.count
    }
    
    private var visitedCountriesCount: Int {
        visitedVisits.count
    }
    
    private var visitedPercentage: Double {
        guard totalCountriesCount > 0 else { return 0 }
        return Double(visitedCountriesCount) / Double(totalCountriesCount) * 100
    }
    
    private var visitedCountries: [Country] {
        let visitedIDs = Set(visitedVisits.map { $0.countryId })
        return vm.countries.filter { visitedIDs.contains($0.id) }
    }
    
    private var visitedThisYear: [(country: Country, date: Date)] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let byId = Dictionary(uniqueKeysWithValues: vm.countries.map { ($0.id, $0) })
        
        return visitedVisits
            .compactMap { visit -> (country: Country, date: Date)? in
                // Get country first
                guard let country = byId[visit.countryId] else {
                    return nil
                }
                
                // For visited countries, use visitedDate (should always exist for visited)
                // If somehow missing, fall back to updatedAt to avoid losing the data
                guard let date = visit.visitedDate ?? (visit.isVisited ? visit.updatedAt : nil) else {
                    return nil
                }
                
                // Check if the date is in the current year
                guard calendar.component(.year, from: date) == currentYear else {
                    return nil
                }
                
                return (country: country, date: date)
            }
            .sorted { $0.date > $1.date }
    }
    
    private var visitedByContinent: [(continent: Continent, visited: Int, total: Int, percentage: Double)] {
        let grouped = Dictionary(grouping: vm.countries, by: { $0.continent })
        
        return Continent.allCases.map { continent in
            let all = grouped[continent] ?? []
            let visitedIDs = Set(visitedVisits.map { $0.countryId })
            let visited = all.filter { visitedIDs.contains($0.id) }.count
            let percentage = all.count > 0 ? Double(visited) / Double(all.count) * 100 : 0
            return (continent: continent, visited: visited, total: all.count, percentage: percentage)
        }
        .filter { $0.total > 0 }
        .sorted { $0.percentage > $1.percentage }
    }
    
    private var recentVisits: [(country: Country, date: Date?)] {
        let byId = Dictionary(uniqueKeysWithValues: vm.countries.map { ($0.id, $0) })
        
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
            ZStack {
                List {
                    // MARK: - Overview Section
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            // Main stat card
                            VStack(spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(visitedCountriesCount)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(.green)
                                    Text("/ \(totalCountriesCount)")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text("Countries Visited")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.green)
                                            .frame(width: geometry.size.width * (visitedPercentage / 100), height: 8)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(visitedPercentage, specifier: "%.1f")% of the world")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Overview")
                    }
                    
                    // MARK: - Quick Stats
                    Section {
                        QuickStatCard(
                            icon: "calendar",
                            value: "\(visitedThisYear.count)",
                            label: "Visited This Year",
                            color: .orange
                        )
                        .frame(height: 80)
                    } header: {
                        Text("Quick Stats")
                    }
                    
                    // MARK: - This Year Section
                    if !visitedThisYear.isEmpty {
                        Section {
                            ForEach(visitedThisYear.prefix(5), id: \.country.id) { item in
                                NavigationLink {
                                    CountryDetailScreen(country: item.country)
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(item.country.flagEmoji)
                                            .font(.title2)
                                        
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
                                }
                            }
                            
                            // Show "View All" button if there are more than 5
                            if visitedThisYear.count > 5 {
                                NavigationLink {
                                    VisitedThisYearListView(visits: visitedThisYear)
                                } label: {
                                    HStack {
                                        Text("View All \(visitedThisYear.count) Countries")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .foregroundStyle(.blue)
                                    .padding(.vertical, 8)
                                }
                            }
                        } header: {
                            Text("Visited This Year (\(visitedThisYear.count))")
                        }
                    }
                    
                    // MARK: - Visited by Continent
                    Section {
                        ForEach(visitedByContinent, id: \.continent.id) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.continent.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(item.visited) / \(item.total)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("(\(item.percentage, specifier: "%.0f")%)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Progress bar for continent
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(continentColor(for: item.percentage))
                                            .frame(width: geometry.size.width * (item.percentage / 100), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Progress by Continent")
                    }
                    
                    // MARK: - Visited Countries Preview
                    if !visitedCountries.isEmpty {
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(visitedCountries) { country in
                                        NavigationLink {
                                            CountryDetailScreen(country: country)
                                        } label: {
                                            VStack(spacing: 4) {
                                                Text(country.flagEmoji)
                                                    .font(.system(size: 32))
                                                Text(country.name)
                                                    .font(.caption2)
                                                    .lineLimit(1)
                                                    .frame(width: 70)
                                            }
                                            .padding(8)
                                            .background(.thinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("All Visited Countries")
                        }
                    }
                    
                    // MARK: - Recent Visits
                    Section {
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
                                            .font(.title2)
                                        
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
                                }
                            }
                        }
                    } header: {
                        Text("Recent Visits")
                    }
                }
                
                // Loading overlay
                if vm.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading statistics...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
                }
            }
            .navigationTitle("Stats")
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Helper Methods
    
    private func continentColor(for percentage: Double) -> Color {
        switch percentage {
        case 75...:
            return .green
        case 50..<75:
            return .blue
        case 25..<50:
            return .orange
        default:
            return .red
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Stats ViewModel
    
    @MainActor
    final class StatsViewModel: ObservableObject {
        @Published private(set) var countries: [Country] = []
        @Published private(set) var isLoading = false
        
        private let service = CountryDataService.shared
        
        init() {
            print("📊 StatsViewModel initialized")
            load()
        }
        
        func load() {
            print("📊 StatsViewModel.load() called")
            isLoading = true
            
            // Load countries
            Task(priority: .userInitiated) {
                print("📊 About to call CountryDataService.loadCountries()")
                let loadedCountries = service.loadCountries()
                print("📊 Received \(loadedCountries.count) countries from service")
                
                self.countries = loadedCountries
                self.isLoading = false
                print("📊 Updated StatsViewModel with \(loadedCountries.count) countries")
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private struct QuickStatCard: View {
        let icon: String
        let value: String
        let label: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
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
}
// MARK: - Visited This Year List View

struct VisitedThisYearListView: View {
    let visits: [(country: Country, date: Date)]
    
    var body: some View {
        List {
            ForEach(visits, id: \.country.id) { item in
                NavigationLink {
                    CountryDetailScreen(country: item.country)
                } label: {
                    HStack(spacing: 12) {
                        Text(item.country.flagEmoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.country.name)
                                .font(.body)
                            Text(item.country.continent.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formattedDate(item.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Visited This Year")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

