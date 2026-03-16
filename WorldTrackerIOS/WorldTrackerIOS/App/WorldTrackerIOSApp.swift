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
            
            let localRepo = SwiftDataVisitRepository(context: context)
            let cloudRepo = FirestoreVisitRepository()
            let syncService = SyncService(
                localRepository: localRepo,
                cloudRepository: cloudRepo
            )
            
            _appState = StateObject(
                wrappedValue: AppState(
                    repository: localRepo,
                    syncService: syncService
                )
            )
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .environmentObject(authService)
                .task(id: authService.authState) {
                    await handleAuthStateChange()
                }
        }
        .modelContainer(container)
    }
    
    @MainActor
    private func handleAuthStateChange() async {
        switch authService.authState {
        case .signedIn:
            // User signed in - load data and sync
            await appState.handleSignIn()
        case .signedOut:
            // User signed out - clear data
            appState.handleSignOut()
        case .unknown:
            // Initial state - do nothing
            break
        }
    }
}
