//
//  CountriesScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI

struct CountriesScreen: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = CountriesViewModel()
    @State private var isSearchFocused = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Continent filter chips - shown when search is active
                if isSearchFocused || vm.isSearching {
                    continentFilterChips
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGroupedBackground))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ZStack {
                    if vm.isSearching {
                        // Show flat list when searching
                        searchResultsList
                            .transition(.opacity)
                    } else {
                        // Show continent grid when not searching
                        continentGrid
                            .transition(.opacity)
                    }
                    
                    if vm.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading countries...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.9))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isSearchFocused)
            .animation(.easeInOut(duration: 0.25), value: vm.isSearching)
            .navigationTitle("Countries")
            .searchable(text: $vm.searchText, isPresented: $isSearchFocused, prompt: "Search countries")
            .onChange(of: vm.isSearching) { oldValue, newValue in
                // Reset continent filter when search is cleared
                if !newValue && vm.selectedContinent != nil {
                    vm.selectedContinent = nil
                }
            }
            .onChange(of: isSearchFocused) { oldValue, newValue in
                // Reset continent filter when search is dismissed (Cancel button)
                if !newValue && vm.selectedContinent != nil {
                    vm.selectedContinent = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.load()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
    }
    
    // MARK: - Continent Filter Chips
    
    private var continentFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                FilterChip(
                    title: "All",
                    isSelected: vm.selectedContinent == nil,
                    action: {
                        vm.selectedContinent = nil
                    }
                )
                
                // Individual continent chips
                ForEach(Continent.allCases) { continent in
                    FilterChip(
                        title: continent.displayName,
                        isSelected: vm.selectedContinent == continent,
                        action: {
                            vm.selectedContinent = continent
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Continent Grid View
    
    private var continentGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(vm.groupedByContinent, id: \.continent.id) { section in
                    NavigationLink {
                        ContinentCountriesView(
                            continent: section.continent,
                            countries: section.countries,
                            appState: appState
                        )
                    } label: {
                        ContinentCard(
                            continent: section.continent,
                            totalCount: section.countries.count,
                            visitedCount: section.countries.filter { appState.isVisited($0.id) }.count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .overlay {
            if !vm.isLoading && vm.groupedByContinent.isEmpty {
                if let error = vm.loadError {
                    ContentUnavailableView(
                        "Failed to Load Countries",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    ContentUnavailableView(
                        "No Countries",
                        systemImage: "globe",
                        description: Text("No countries available.")
                    )
                }
            }
        }
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        List {
            // Result count section
            Section {
                EmptyView()
            } header: {
                resultCountHeader
            }
            .listRowInsets(EdgeInsets())
            
            // Country results
            Section {
                ForEach(vm.filteredCountries) { country in
                    let visited = appState.isVisited(country.id)
                    
                    NavigationLink {
                        CountryDetailScreen(country: country)
                    } label: {
                        CountryRow(country: country, isVisited: visited)
                    }
                    .listRowBackground(visited ? Color.green.opacity(0.12) : Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !vm.isLoading && vm.filteredCountries.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No countries match your search")
                )
            }
        }
    }
    
    // MARK: - Result Count Header
    
    private var resultCountHeader: some View {
        HStack {
            let count = vm.filteredCountries.count
            let filterText = vm.selectedContinent?.displayName ?? "All Continents"
            
            if count > 0 {
                Text("\(count) \(count == 1 ? "country" : "countries")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if vm.isFiltering {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(filterText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .textCase(nil)
        .padding(.horizontal, 4)
    }
}

// MARK: - Continent Card

private struct ContinentCard: View {
    let continent: Continent
    let totalCount: Int
    let visitedCount: Int
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(visitedCount) / Double(totalCount) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(continentEmoji)
                    .font(.system(size: 32))
                Spacer()
            }
            
            // Title
            Text(continent.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("\(visitedCount) / \(totalCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(continentColor)
                            .frame(width: geometry.size.width * (percentage / 100), height: 4)
                    }
                }
                .frame(height: 4)
                
                if visitedCount > 0 {
                    Text("\(Int(percentage))% visited")
                        .font(.caption)
                        .foregroundStyle(continentColor)
                } else {
                    Text("Not visited yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var continentEmoji: String {
        switch continent {
        case .africa: return "🌍"
        case .antarctica: return "🇦🇶"
        case .asia: return "🌏"
        case .europe: return "🇪🇺"
        case .northAmerica: return "🌎"
        case .southAmerica: return "🗺️"
        case .oceania: return "🏝️"
        }
    }
    
    private var continentColor: Color {
        switch percentage {
        case 75...: return .green
        case 50..<75: return .blue
        case 25..<50: return .orange
        case 0.1..<25: return .yellow
        default: return .gray
        }
    }
}

// MARK: - Continent Countries View

private struct ContinentCountriesView: View {
    let continent: Continent
    let countries: [Country]
    let appState: AppState
    
    @State private var searchText = ""
    
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return countries
        }
        return countries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredCountries) { country in
                let visited = appState.isVisited(country.id)
                
                NavigationLink {
                    CountryDetailScreen(country: country)
                } label: {
                    CountryRow(country: country, isVisited: visited)
                }
                .listRowBackground(visited ? Color.green.opacity(0.12) : Color.clear)
            }
        }
        .navigationTitle(continent.displayName)
        .searchable(text: $searchText, prompt: "Search \(continent.displayName)")
    }
}

// MARK: - Country Row

private struct CountryRow: View {
    let country: Country
    let isVisited: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(country.flagEmoji).font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .foregroundStyle(.primary)
            }

            Spacer()

            if isVisited {
                Text("Visited")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

