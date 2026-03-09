//
//  WorldTrackerIOSApp.swift
//  WorldTrackerIOS
//
//  Created by seren on 24.02.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct WorldTrackerIOSApp: App {
    @StateObject private var authService = AuthService()

    private let container: ModelContainer
    @StateObject private var appState: AppState

    init() {
        FirebaseApp.configure()

        do {
            container = try ModelContainer(for: VisitEntity.self)
            let context = ModelContext(container)
            let repo = SwiftDataVisitRepository(context: context)
            _appState = StateObject(wrappedValue: AppState(repository: repo))
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .environmentObject(authService)
        }
        .modelContainer(container)
    }
}
