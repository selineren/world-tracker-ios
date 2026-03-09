//
//  RootTabVİew.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var authService: AuthService

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
    }
}
