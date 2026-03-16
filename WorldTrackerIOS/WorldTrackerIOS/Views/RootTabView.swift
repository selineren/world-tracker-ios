//
//  RootTabView.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            MapScreen()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            CountriesScreen()
                .tabItem {
                    Label("Countries", systemImage: "list.bullet")
                }

            StatsScreen()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            Group {
                if authService.isSignedIn {
                    AccountScreen()
                } else {
                    AuthScreen()
                }
            }
            .tabItem {
                Label("Account", systemImage: "person.circle")
            }
        }
        .task {
            if authService.isSignedIn {
                do {
                    try await appState.syncWithCloud()
                } catch {
                    print("⚠️ Initial sync failed in RootTabView: \(error)")
                }
            }
        }
    }
}
