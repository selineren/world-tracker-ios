//
//  Continent.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import Foundation

enum Continent: String, CaseIterable, Identifiable {
    case europe
    case asia
    case africa
    case northAmerica
    case southAmerica
    case australia
    case antarctica
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .europe: return "Europe"
        case .asia: return "Asia"
        case .africa: return "Africa"
        case .northAmerica: return "North America"
        case .southAmerica: return "South America"
        case .australia: return "Australia"
        case .antarctica: return "Antarctica"
        }
    }
}
