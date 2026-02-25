//
//  CountriesScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import Foundation
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
                            CountryRow(
                                country: country,
                                isVisited: appState.isVisited(country.id)
                            ) {
                                appState.setVisited(country.id, isVisited: !appState.isVisited(country.id))
                            }
                        }
                    }
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
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Text(country.flagEmoji)
                    .font(.title2)
                
                Text(country.name)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isVisited {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                } else {
                    Image(systemName: "circle")
                        .imageScale(.large)
                        .opacity(0.25)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
