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
            List {
                ForEach(vm.groupedByContinent, id: \.continent.id) { section in
                    Section(section.continent.displayName) {
                        ForEach(section.countries) { country in
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
            }
            .overlay {
                if vm.groupedByContinent.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term.")
                    )
                }
            }
            .navigationTitle("Countries")
            .searchable(text: $vm.searchText, prompt: "Search countries")
        }
    }
}

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
