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
            // Create model configuration with migration options
            let schema = Schema([VisitEntity.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
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
            // Print detailed error information
            print("❌ SwiftData container creation failed: \(error)")
            if let swiftDataError = error as? SwiftData.SwiftDataError {
                print("❌ SwiftData error details: \(swiftDataError)")
            }
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
