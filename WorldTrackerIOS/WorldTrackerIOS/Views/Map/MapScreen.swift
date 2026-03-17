//
//  MapScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI
import FirebaseAuth
import MapKit

struct MapScreen: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: AuthService
    
    @State private var showSyncStatus = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VisitedCountriesMapView(
                    visitedCountryIDs: appState.visitedCountryIDs
                )
                .edgesIgnoringSafeArea(.top)
                
                // Overlay UI Elements
                VStack(alignment: .leading, spacing: 12) {
                    // Stats Card (top left)
                    if showingStats {
                        statsCard
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Legend (bottom left)
                    legendCard
                }
                .padding()
                
                // Sync status indicator (top center)
                if showSyncStatus {
                    VStack {
                        SyncStatusView(
                            status: appState.syncStatus,
                            onRetry: {
                                Task {
                                    await appState.retrySyncIfNeeded()
                                }
                            },
                            onDismiss: {
                                withAnimation {
                                    showSyncStatus = false
                                }
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingStats.toggle()
                        }
                    } label: {
                        Image(systemName: showingStats ? "chart.bar.fill" : "chart.bar")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Compact sync status in toolbar
                        SyncStatusToolbarItem(status: appState.syncStatus)
                        
                        refreshButton
                    }
                }
            }
            .task(id: authService.user?.uid) {
                await handleAuthStateChange()
            }
            .onChange(of: appState.syncStatus) { oldValue, newValue in
                // Show status banner when status changes
                if case .idle = oldValue, case .idle = newValue {
                    // Don't show for idle -> idle
                } else {
                    withAnimation {
                        showSyncStatus = true
                    }
                    
                    // Auto-hide success message after 3 seconds
                    if case .success = newValue {
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            withAnimation {
                                showSyncStatus = false
                            }
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await refreshMapData()
                }
            }
        }
    }
    
    @State private var showingStats = true
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .foregroundStyle(.blue)
                Text("Countries Visited")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(appState.visitedCountryIDs.count)")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                Text("/ 238")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            if appState.visitedCountryIDs.count > 0 {
                let percentage = Double(appState.visitedCountryIDs.count) / 238.0 * 100
                Text("\(Int(percentage))% of the world")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Legend Card
    
    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption.bold())
                .foregroundStyle(.primary)
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Text("Visited")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 12, height: 12)
                Text("Not visited")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Refresh Button
    
    private var refreshButton: some View {
        Button {
            Task {
                await refreshMapData()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(appState.isSyncing || !authService.isSignedIn)
    }
    
    // MARK: - Data Management
    
    private func handleAuthStateChange() async {
        guard authService.isSignedIn else {
            return
        }
        await refreshMapData()
    }
    
    private func refreshMapData() async {
        guard authService.isSignedIn else {
            return
        }
        
        appState.refreshFromPersistence()
        await appState.syncWithCloud()
    }
}


