//
//  StatsScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI

struct StatsScreen: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Stats")
                    .font(.title).bold()

                Text("Visited countries: \(appState.visitedCount)")
                    .font(.headline)

                Text("More stats will be added in Phase 2.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Stats")
        }
    }
}
