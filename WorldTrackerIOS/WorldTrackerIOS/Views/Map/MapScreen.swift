//
//  MapScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI

struct MapScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Map")
                    .font(.title).bold()

                Text("Map view will be added in Phase 2.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Map")
        }
    }
}
