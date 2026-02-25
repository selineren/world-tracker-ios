//
//  RootTabVİew.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import Foundation
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            MapScreen()
                .tabItem { Label("Map", systemImage: "map") }
            
            CountriesScreen()
                .tabItem { Label("Countries", systemImage: "list.bullet") }
            
            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
        }
    }
}
