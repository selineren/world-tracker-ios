//
//  MockCountryService.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import Foundation

final class MockCountryService {
    
    func loadCountries() -> [Country] {
        return [
            Country(id: "FR", name: "France", continent: .europe, flagEmoji: "🇫🇷",
                    centroid: Coordinate(latitude: 48.8566, longitude: 2.3522)),
            
            Country(id: "DE", name: "Germany", continent: .europe, flagEmoji: "🇩🇪",
                    centroid: Coordinate(latitude: 52.5200, longitude: 13.4050)),
            
            Country(id: "IT", name: "Italy", continent: .europe, flagEmoji: "🇮🇹",
                    centroid: Coordinate(latitude: 41.9028, longitude: 12.4964)),
            
            
            Country(id: "US", name: "United States", continent: .northAmerica, flagEmoji: "🇺🇸",
                    centroid: Coordinate(latitude: 38.9072, longitude: -77.0369)),
            
            Country(id: "CA", name: "Canada", continent: .northAmerica, flagEmoji: "🇨🇦",
                    centroid: Coordinate(latitude: 45.4215, longitude: -75.6972)),
            
            Country(id: "MX", name: "Mexico", continent: .northAmerica, flagEmoji: "🇲🇽",
                    centroid: Coordinate(latitude: 19.4326, longitude: -99.1332)),
            
            
            Country(id: "JP", name: "Japan", continent: .asia, flagEmoji: "🇯🇵",
                    centroid: Coordinate(latitude: 35.6762, longitude: 139.6503)),
            
            Country(id: "CN", name: "China", continent: .asia, flagEmoji: "🇨🇳",
                    centroid: Coordinate(latitude: 39.9042, longitude: 116.4074)),
            
            Country(id: "IN", name: "India", continent: .asia, flagEmoji: "🇮🇳",
                    centroid: Coordinate(latitude: 28.6139, longitude: 77.2090)),
            
            
            Country(id: "BR", name: "Brazil", continent: .southAmerica, flagEmoji: "🇧🇷",
                    centroid: Coordinate(latitude: -15.8267, longitude: -47.9218)),
            
            Country(id: "AR", name: "Argentina", continent: .southAmerica, flagEmoji: "🇦🇷",
                    centroid: Coordinate(latitude: -34.6037, longitude: -58.3816)),
            
            
            Country(id: "AU", name: "Australia", continent: .oceania, flagEmoji: "🇦🇺",
                    centroid: Coordinate(latitude: -35.2809, longitude: 149.1300)),
            
            
            Country(id: "EG", name: "Egypt", continent: .africa, flagEmoji: "🇪🇬",
                    centroid: Coordinate(latitude: 30.0444, longitude: 31.2357)),
            
            Country(id: "ZA", name: "South Africa", continent: .africa, flagEmoji: "🇿🇦",
                    centroid: Coordinate(latitude: -25.7479, longitude: 28.2293))
        ]
    }
}
