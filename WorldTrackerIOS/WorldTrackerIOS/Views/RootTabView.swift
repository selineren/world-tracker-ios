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
    @EnvironmentObject private var achievementNotifier: AchievementNotifier

    @State private var selectedTab: Tab = .map
    @State private var hasSeededAchievements = false
    @State private var achievementCheckTask: Task<Void, Never>?

    enum Tab {
        case map
        case countries
        case stats
        case compare
        case account
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen(
                onNavigateToStats: { selectedTab = .stats },
                onNavigateToCountries: { selectedTab = .countries }
            )
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
        .onChange(of: appState.visits) { _, _ in
            let countries = CountryDataService.shared.loadCountries()
            if !hasSeededAchievements {
                hasSeededAchievements = true
                if achievementNotifier.hasPriorSeenData {
                    // Normal session: seed so existing achievements don't re-fire on launch.
                    achievementNotifier.seed(visits: appState.visits, countries: countries)
                    return
                }
                // seenIDs is empty (fresh install or debug reset): fall through to check.
            }
            achievementCheckTask?.cancel()
            achievementCheckTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                achievementNotifier.check(
                    visits: appState.visits,
                    countries: CountryDataService.shared.loadCountries()
                )
            }
        }
    }
}
