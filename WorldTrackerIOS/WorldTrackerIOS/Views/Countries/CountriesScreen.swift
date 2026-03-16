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
    
    var body: some View {
        NavigationStack {
            ZStack {
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
            .navigationTitle("Countries")
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
