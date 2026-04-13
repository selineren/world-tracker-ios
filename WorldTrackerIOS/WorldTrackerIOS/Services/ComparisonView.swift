//
//  ComparisonView.swift
//  WorldTrackerIOS
//
//  Created by seren on 13.04.2026.
//

import SwiftUI
import Combine

struct ComparisonView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ComparisonViewModel()
    @State private var displayMode: DisplayMode = .list
    @State private var mapZoomLevel: MapZoomLevel = .continent
    
    enum DisplayMode {
        case list
        case map
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Display Mode Picker (List vs Map)
                Picker("Display Mode", selection: $displayMode) {
                    Text("List").tag(DisplayMode.list)
                    Text("Map").tag(DisplayMode.map)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                
                // Mode Picker (Visited vs Wishlist)
                Picker("Comparison Mode", selection: $viewModel.selectedMode) {
                    Text("Visited").tag(ComparisonMode.visited)
                    Text("Wishlist").tag(ComparisonMode.wishlist)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on display mode
                if displayMode == .list {
                    listView
                } else {
                    mapView
                }
            }
            .navigationTitle("Travel Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.regenerateMockData()
                    } label: {
                        Label("Regenerate Mock Data", systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.loadComparison(yourVisits: appState.visits)
            }
            .onChange(of: appState.visits) { _, newVisits in
                viewModel.loadComparison(yourVisits: newVisits)
            }
            .onChange(of: viewModel.selectedMode) { _, _ in
                viewModel.loadComparison(yourVisits: appState.visits)
            }
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        VStack(spacing: 0) {
            // Stats Summary Card
            statsCard
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Main Comparison List
            List {
                // Section 1: Yours
                if !viewModel.currentComparison.yours.isEmpty {
                    Section {
                        ForEach(viewModel.yourCountries, id: \.id) { country in
                            CountryRow(country: country, badge: .yours)
                        }
                    } header: {
                        Text("Only You (\(viewModel.currentComparison.yours.count))")
                    }
                }
                
                // Section 2: Shared
                if !viewModel.currentComparison.shared.isEmpty {
                    Section {
                        ForEach(viewModel.sharedCountries, id: \.id) { country in
                            CountryRow(country: country, badge: .shared)
                        }
                    } header: {
                        Text("Both (\(viewModel.currentComparison.shared.count))")
                    }
                }
                
                // Section 3: Theirs
                if !viewModel.currentComparison.theirs.isEmpty {
                    Section {
                        ForEach(viewModel.theirCountries, id: \.id) { country in
                            CountryRow(country: country, badge: .theirs)
                        }
                    } header: {
                        Text("Only Them (\(viewModel.currentComparison.theirs.count))")
                    }
                }
                
                // Empty state
                if viewModel.currentComparison.totalUnique == 0 {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No data to compare")
                                .font(.headline)
                            Text("Mark some countries as \(viewModel.selectedMode == .visited ? "visited" : "wishlisted") to see the comparison")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        VStack(spacing: 0) {
            // Stats Summary Card
            statsCard
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Map Legend
            mapLegend
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Map
            ComparisonMapView(
                comparison: viewModel.currentComparison,
                zoomLevel: $mapZoomLevel,
                onCountryTapped: { countryId in
                    print("Tapped country: \(countryId)")
                }
            )
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Overlap",
                    value: "\(Int(viewModel.currentComparison.overlapPercentage))%",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    title: "Total Unique",
                    value: "\(viewModel.currentComparison.totalUnique)",
                    color: .purple
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    title: "Shared",
                    value: "\(viewModel.currentComparison.shared.count)",
                    color: .green
                )
            }
            .padding()
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Map Legend
    
    private var mapLegend: some View {
        HStack(spacing: 16) {
            LegendItem(color: .green, label: "Both", count: viewModel.currentComparison.shared.count)
            LegendItem(color: .blue, label: "You", count: viewModel.currentComparison.yours.count)
            LegendItem(color: .orange, label: "Them", count: viewModel.currentComparison.theirs.count)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
            Text("(\(count))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CountryRow: View {
    let country: Country
    let badge: ComparisonBadge
    
    var body: some View {
        HStack(spacing: 12) {
            Text(country.flagEmoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .font(.body)
                Text(country.continent.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            badge.icon
                .font(.caption)
                .foregroundStyle(badge.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badge.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Badge Type

enum ComparisonBadge {
    case yours
    case shared
    case theirs
    
    var icon: some View {
        switch self {
        case .yours:
            return Image(systemName: "person.fill")
        case .shared:
            return Image(systemName: "person.2.fill")
        case .theirs:
            return Image(systemName: "person.fill")
        }
    }
    
    var color: Color {
        switch self {
        case .yours:
            return .blue
        case .shared:
            return .green
        case .theirs:
            return .orange
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ComparisonViewModel: ObservableObject {
    @Published var selectedMode: ComparisonMode = .visited
    @Published private(set) var visitedComparison: TravelComparisonResult
    @Published private(set) var wishlistComparison: TravelComparisonResult
    @Published private(set) var mockFriendVisits: [String: Visit]
    
    private let countryService = CountryDataService.shared
    private var allCountries: [Country] = []
    
    // Current comparison based on selected mode
    var currentComparison: TravelComparisonResult {
        selectedMode == .visited ? visitedComparison : wishlistComparison
    }
    
    // Convert country IDs to Country objects
    var yourCountries: [Country] {
        getCountries(for: Array(currentComparison.yours))
    }
    
    var sharedCountries: [Country] {
        getCountries(for: Array(currentComparison.shared))
    }
    
    var theirCountries: [Country] {
        getCountries(for: Array(currentComparison.theirs))
    }
    
    init() {
        // Initialize with empty comparisons
        self.visitedComparison = TravelComparisonResult(
            yours: [],
            shared: [],
            theirs: [],
            mode: .visited
        )
        self.wishlistComparison = TravelComparisonResult(
            yours: [],
            shared: [],
            theirs: [],
            mode: .wishlist
        )
        
        // Load countries
        self.allCountries = countryService.loadCountries()
        
        // Generate initial mock data
        self.mockFriendVisits = Self.generateMockFriendVisits(allCountries: allCountries)
    }
    
    func loadComparison(yourVisits: [String: Visit]) {
        // Perform comparison for visited countries
        visitedComparison = TravelComparisonEngine.compare(
            yourVisits: yourVisits,
            theirVisits: mockFriendVisits,
            mode: .visited
        )
        
        // Perform comparison for wishlist countries
        wishlistComparison = TravelComparisonEngine.compare(
            yourVisits: yourVisits,
            theirVisits: mockFriendVisits,
            mode: .wishlist
        )
    }
    
    func regenerateMockData() {
        mockFriendVisits = Self.generateMockFriendVisits(allCountries: allCountries)
        // Trigger re-comparison (will be done by onChange handler)
        objectWillChange.send()
    }
    
    // MARK: - Mock Data Generation
    
    static func generateMockFriendVisits(allCountries: [Country]) -> [String: Visit] {
        // Pick 10-15 random countries for friend's visited list
        let visitedCount = Int.random(in: 10...15)
        let visitedCountries = allCountries.shuffled().prefix(visitedCount)
        
        // Pick 5-10 random countries for friend's wishlist (different from visited)
        let remainingCountries = allCountries.filter { country in
            !visitedCountries.contains(where: { $0.id == country.id })
        }
        let wishlistCount = Int.random(in: 5...10)
        let wishlistCountries = remainingCountries.shuffled().prefix(wishlistCount)
        
        var mockVisits: [String: Visit] = [:]
        
        // Add visited countries
        for country in visitedCountries {
            mockVisits[country.id] = Visit(
                countryId: country.id,
                isVisited: true,
                wantToVisit: false,
                visitedDate: Date().addingTimeInterval(-Double.random(in: 0...31536000)), // Random date in last year
                notes: "Mock visited country",
                photos: [],
                updatedAt: Date()
            )
        }
        
        // Add wishlist countries
        for country in wishlistCountries {
            mockVisits[country.id] = Visit(
                countryId: country.id,
                isVisited: false,
                wantToVisit: true,
                visitedDate: nil,
                notes: "Mock wishlist country",
                photos: [],
                updatedAt: Date()
            )
        }
        
        return mockVisits
    }
    
    // MARK: - Helpers
    
    private func getCountries(for countryIds: [String]) -> [Country] {
        let countryDict = Dictionary(uniqueKeysWithValues: allCountries.map { ($0.id, $0) })
        return countryIds.compactMap { countryDict[$0] }.sorted { $0.name < $1.name }
    }
}

// MARK: - Preview

#Preview {
    ComparisonView()
}
