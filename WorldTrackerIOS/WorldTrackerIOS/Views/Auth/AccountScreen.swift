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
    @State private var showingChangePassword = false
    @State private var showingDeleteAccount = false
    
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
    
    // MARK: - Helper Functions for Profile Avatar
    
    /// Extract initials from email address
    /// - Parameter email: User's email address
    /// - Returns: 1-2 character initials (e.g., "JD" from "john.doe@example.com")
    private func initials(from email: String) -> String {
        // Get the part before @ symbol
        let components = email.components(separatedBy: "@")
        guard let namePart = components.first, !namePart.isEmpty else {
            return "?" // Fallback for invalid email
        }
        
        // Split by common separators (., _, -)
        let nameComponents = namePart.components(separatedBy: CharacterSet(charactersIn: "._-"))
            .filter { !$0.isEmpty }
        
        if nameComponents.count >= 2 {
            // Two-letter initials from first two components (e.g., "john.doe" → "JD")
            let first = nameComponents[0].prefix(1).uppercased()
            let second = nameComponents[1].prefix(1).uppercased()
            return first + second
        } else if let first = nameComponents.first {
            // Single letter from first component (e.g., "john" → "J")
            return String(first.prefix(1).uppercased())
        } else {
            return "?" // Fallback
        }
    }
    
    /// Generate consistent avatar color from email
    /// - Parameter email: User's email address
    /// - Returns: Color that will be consistent for the same email across all app launches
    private func avatarColor(for email: String) -> Color {
        // Define a palette of pleasant colors for avatars
        let colors: [Color] = [
            .blue,
            .green,
            .orange,
            .purple,
            .pink,
            .teal,
            .indigo,
            .cyan
        ]
        
        // Generate stable hash from email using simple character-based algorithm
        // This ensures the same email always produces the same color across all sessions
        var hash = 0
        for char in email.utf8 {
            hash = (hash &* 31 &+ Int(char)) & 0x7FFFFFFF
        }
        
        let index = hash % colors.count
        return colors[index]
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile Section
                Section {
                    VStack(spacing: 12) {
                        // Avatar Circle with Initials
                        ZStack {
                            Circle()
                                .fill(avatarColor(for: authService.userEmail))
                                .frame(width: 64, height: 64)
                            
                            Text(initials(from: authService.userEmail))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        // Email
                        Text(authService.userEmail)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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

                // MARK: - Settings Section
                Section {
                    Button {
                        showingChangePassword = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 32)
                            
                            Text("Change Password")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Settings")
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
                
                // MARK: - Danger Zone Section
                Section {
                    Button {
                        showingDeleteAccount = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                                .frame(width: 32)
                            
                            Text("Delete Account")
                                .foregroundStyle(.red)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Danger Zone")
                        .foregroundStyle(.red)
                } footer: {
                    Text("Deleting your account is permanent and cannot be undone. All your travel data will be lost.")
                        .foregroundStyle(.red)
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
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
            }
            .sheet(isPresented: $showingDeleteAccount) {
                DeleteAccountView()
            }
            .task {
                // Load countries and total count from CountryDataService
                let loadedCountries = CountryDataService.shared.loadCountries()
                countries = loadedCountries
                totalCountries = loadedCountries.count
            }
        }
    }
}
