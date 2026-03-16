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
    
    @State private var isRefreshing = false
    @State private var lastSyncDate: Date?
    @State private var syncError: String?
    @State private var showingStats = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VisitedCountriesMapView(
                    visitedCountryIDs: appState.visitedCountryIDs
                )
                .ignoresSafeArea(edges: .bottom)
                
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
                if isRefreshing {
                    VStack {
                        syncStatusBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                }
                
                // Error banner (top)
                if let error = syncError {
                    VStack {
                        errorBanner(message: error)
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
                    refreshButton
                }
            }
            .task(id: authService.user?.uid) {
                await handleAuthStateChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await refreshMapData()
                }
            }
        }
    }
    
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
    
    // MARK: - Style Picker Button
    
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
    
    // MARK: - Banners
    
    private var syncStatusBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("Syncing...")
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.9))
        .cornerRadius(8)
        .padding(.top, 8)
    }
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                withAnimation {
                    syncError = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.red.opacity(0.9))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var refreshButton: some View {
        Button {
            Task {
                await refreshMapData()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(isRefreshing || !authService.isSignedIn)
    }
    
    // MARK: - Data Management
    
    private func handleAuthStateChange() async {
        guard authService.isSignedIn else {
            syncError = nil
            lastSyncDate = nil
            return
        }
        await refreshMapData()
    }
    
    private func refreshMapData() async {
        guard authService.isSignedIn else {
            return
        }
        
        withAnimation {
            isRefreshing = true
            syncError = nil
        }
        
        do {
            appState.refreshFromPersistence()
            try await appState.syncWithCloud()
            appState.refreshFromPersistence()
            lastSyncDate = Date()
            
            withAnimation {
                isRefreshing = false
            }
        } catch {
            withAnimation {
                isRefreshing = false
                syncError = "Sync failed: \(error.localizedDescription)"
            }
            
            Task {
                try? await Task.sleep(for: .seconds(5))
                withAnimation {
                    if syncError != nil {
                        syncError = nil
                    }
                }
            }
        }
    }
}


