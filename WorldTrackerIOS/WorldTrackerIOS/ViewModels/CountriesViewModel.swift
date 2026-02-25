//
//  CountriesViewModel.swift
//  WorldTrackerIOS
//
//  Created by seren on 26.02.2026.
//

import Foundation
import Combine

@MainActor
final class CountriesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var countries: [Country] = []
    
    private let service = MockCountryService()
    
    init() {
        load()
    }
    
    func load() {
        countries = service.loadCountries()
            .sorted { $0.name < $1.name }
    }
    
    var filteredCountries: [Country] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return countries
        }
        let q = searchText.lowercased()
        return countries.filter { $0.name.lowercased().contains(q) }
    }
    
    var groupedByContinent: [(continent: Continent, countries: [Country])] {
        let grouped = Dictionary(grouping: filteredCountries, by: { $0.continent })
        return Continent.allCases.compactMap { c in
            guard let items = grouped[c], !items.isEmpty else { return nil }
            return (c, items.sorted { $0.name < $1.name })
        }
    }
}
