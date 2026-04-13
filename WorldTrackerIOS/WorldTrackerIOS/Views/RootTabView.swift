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
            
            // Travel Comparison (NEW!)
            ComparisonView()
                .tabItem {
                    Label("Compare", systemImage: "person.2.fill")
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
        .onAppear {
            // Ensure tab bar is always visible and properly styled
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .task {
            if authService.isSignedIn {
                await appState.syncWithCloud()
            }
        }
    }
}
