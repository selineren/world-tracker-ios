//
//  AccountScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 9.03.2026.
//

import SwiftUI

struct AccountScreen: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState
    @State private var errorMessage: String?
    @State private var totalCountries: Int = 0
    @State private var countries: [Country] = []
    
    // MARK: - Computed Properties for Travel Stats
    
    /// Number of countries the user has visited
    private var visitedCount: Int {
        appState.visitedCountryIDs.count
    }
    
    /// Number of countries on the user's wishlist
    private var wishlistCount: Int {
        appState.wantToVisitCountryIDs.count
    }
    
    /// Percentage of the world the user has explored
    private var visitedPercentage: Double {
        guard totalCountries > 0 else { return 0 }
        return Double(visitedCount) / Double(totalCountries) * 100
    }
    
    /// Number of countries visited this year
    private var visitedThisYear: Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        return appState.visits.values
            .filter { $0.isVisited }
            .filter { visit in
                guard let date = visit.visitedDate else { return false }
                return calendar.component(.year, from: date) == currentYear
            }
            .count
    }
    
    /// Achievement summary (total and unlocked counts)
    private var achievementSummary: (total: Int, unlocked: Int) {
        guard !countries.isEmpty else { return (0, 0) }
        
        let achievements = AchievementEngine.calculateAchievements(
            visits: appState.visits,
            countries: countries
        )
        return AchievementEngine.achievementSummary(achievements)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Session Section
                Section("Session") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        Text(authService.userEmail)
                            .font(.body)
                    }
                }
                
                // MARK: - Travel Overview Section
                Section {
                    // Visited Countries
                    HStack(spacing: 12) {
                        Image(systemName: "globe.americas.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(visitedCount) Countries Visited")
                                .font(.headline)
                            
                            Text("\(visitedPercentage, specifier: "%.1f")% of the world")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * (visitedPercentage / 100), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    
                    // Wishlist Countries
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(wishlistCount) Countries on Wishlist")
                                .font(.headline)
                            
                            if wishlistCount > 0 {
                                Text("Places to visit next")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Start planning your next trip")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Travel Overview")
                } footer: {
                    if visitedCount == 0 && wishlistCount == 0 {
                        Text("Start marking countries as visited to track your travel journey!")
                    }
                }
                
                // MARK: - Travel Highlights Section
                Section {
                    // Visited This Year
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(visitedThisYear) Visited This Year")
                                .font(.headline)
                            
                            if visitedThisYear > 0 {
                                Text("Great travel year!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                let currentYear = Calendar.current.component(.year, from: Date())
                                Text("Start your \(String(format: "%d", currentYear)) travels")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    // Achievements
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(achievementSummary.unlocked)/\(achievementSummary.total) Achievements")
                                .font(.headline)
                            
                            if achievementSummary.unlocked > 0 {
                                Text("Keep exploring!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Unlock your first achievement")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Travel Highlights")
                }

                // MARK: - Sign Out Section
                Section {
                    Button("Sign Out", role: .destructive) {
                        do {
                            try authService.signOut()
                            appState.clearLocalDataAfterSignOut()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }

                // MARK: - Error Section
                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Account")
            .task {
                // Load countries and total count from CountryDataService
                let loadedCountries = CountryDataService.shared.loadCountries()
                countries = loadedCountries
                totalCountries = loadedCountries.count
            }
        }
    }
}
