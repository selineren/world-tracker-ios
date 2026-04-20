//
//  RootTabView.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI
import FirebaseAuth

struct RootTabView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var appState: AppState
    
    // Track selected tab - always starts on Map when view is created
    @State private var selectedTab: Tab = .map
    
    enum Tab {
        case map
        case countries
        case stats
        case compare
        case account
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(Tab.map)
            
            CountriesScreen()
                .tabItem {
                    Label("Countries", systemImage: "list.bullet")
                }
                .tag(Tab.countries)

            StatsScreen()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(Tab.stats)
            
            // Travel Comparison
            ComparisonView()
                .tabItem {
                    Label("Compare", systemImage: "person.2.fill")
                }
                .tag(Tab.compare)

            // Account - only visible when signed in (enforced by AuthGatedRootView)
            AccountScreen()
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
                .tag(Tab.account)
        }
        .onAppear {
            // Ensure tab bar is always visible and properly styled
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            #if DEBUG
            print("🗺️ RootTabView appeared with signInCounter=\(authService.signInCounter), selectedTab=\(selectedTab)")
            #endif
        }
        .task {
            // Sync with cloud when tab view appears (user is guaranteed to be signed in)
            await appState.syncWithCloud()
        }
    }
}
