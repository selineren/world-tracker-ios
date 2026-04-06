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
                // Load total countries count from CountryDataService
                let countries = CountryDataService.shared.loadCountries()
                totalCountries = countries.count
            }
        }
    }
}
