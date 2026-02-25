//
//  Country.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import Foundation

struct Country: Identifiable {
    let id: String          // ISO code ("FR", "US")
    let name: String
    let continent: Continent
    let latitude: Double
    let longitude: Double
    let flagEmoji: String
}
