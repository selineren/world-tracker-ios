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
            Country(id: "FR", name: "France", continent: .europe, latitude: 48.8566, longitude: 2.3522, flagEmoji: "🇫🇷"),
            Country(id: "DE", name: "Germany", continent: .europe, latitude: 52.5200, longitude: 13.4050, flagEmoji: "🇩🇪"),
            Country(id: "IT", name: "Italy", continent: .europe, latitude: 41.9028, longitude: 12.4964, flagEmoji: "🇮🇹"),
            
            Country(id: "US", name: "United States", continent: .northAmerica, latitude: 38.9072, longitude: -77.0369, flagEmoji: "🇺🇸"),
            Country(id: "CA", name: "Canada", continent: .northAmerica, latitude: 45.4215, longitude: -75.6972, flagEmoji: "🇨🇦"),
            Country(id: "MX", name: "Mexico", continent: .northAmerica, latitude: 19.4326, longitude: -99.1332, flagEmoji: "🇲🇽"),
            
            Country(id: "JP", name: "Japan", continent: .asia, latitude: 35.6762, longitude: 139.6503, flagEmoji: "🇯🇵"),
            Country(id: "CN", name: "China", continent: .asia, latitude: 39.9042, longitude: 116.4074, flagEmoji: "🇨🇳"),
            Country(id: "IN", name: "India", continent: .asia, latitude: 28.6139, longitude: 77.2090, flagEmoji: "🇮🇳"),
            
            Country(id: "BR", name: "Brazil", continent: .southAmerica, latitude: -15.8267, longitude: -47.9218, flagEmoji: "🇧🇷"),
            Country(id: "AR", name: "Argentina", continent: .southAmerica, latitude: -34.6037, longitude: -58.3816, flagEmoji: "🇦🇷"),
            
            Country(id: "AU", name: "Australia", continent: .australia, latitude: -35.2809, longitude: 149.1300, flagEmoji: "🇦🇺"),
            
            Country(id: "EG", name: "Egypt", continent: .africa, latitude: 30.0444, longitude: 31.2357, flagEmoji: "🇪🇬"),
            Country(id: "ZA", name: "South Africa", continent: .africa, latitude: -25.7479, longitude: 28.2293, flagEmoji: "🇿🇦")
        ]
    }
}
