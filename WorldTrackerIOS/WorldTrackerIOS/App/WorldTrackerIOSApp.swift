//
//  WorldTrackerIOSApp.swift
//  WorldTrackerIOS
//
//  Created by seren on 24.02.2026.
//

import SwiftUI

@main
struct WorldTrackerIOSApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
        }
    }
}
