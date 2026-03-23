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
    @State private var selectedCountryID: String?
    @State private var showCountrySheet = false
    @State private var selectedCountryForDetail: Country?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                VisitedCountriesMapView(
                    visitedCountryIDs: appState.visitedCountryIDs,
                    onCountryTapped: { countryID in
                        selectedCountryID = countryID
                        showCountrySheet = true
                    }
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
            .sheet(isPresented: $showCountrySheet) {
                if let countryID = selectedCountryID {
                    CountryQuickActionSheet(
                        countryID: countryID,
                        appState: appState,
                        onViewDetails: { country in
                            selectedCountryForDetail = country
                            showCountrySheet = false
                        }
                    )
                    .presentationDetents([.height(280), .medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .navigationDestination(item: $selectedCountryForDetail) { country in
                CountryDetailScreen(country: country)
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

// MARK: - Country Quick Action Sheet

struct CountryQuickActionSheet: View {
    let countryID: String
    @ObservedObject var appState: AppState
    let onViewDetails: (Country) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var country: Country?
    @State private var isLoading = true
    
    private var isVisited: Bool {
        appState.isVisited(countryID)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 40)
            } else if let country = country {
                VStack(spacing: 12) {
                    Text(country.flagEmoji)
                        .font(.system(size: 64))
                    
                    Text(country.name)
                        .font(.title2.bold())
                    
                    Text(country.continent.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("Country not found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 40)
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 0) {
                Button {
                    toggleVisited()
                } label: {
                    HStack {
                        Image(systemName: isVisited ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(isVisited ? .green : .gray)
                        
                        Text(isVisited ? "Mark as Not Visited" : "Mark as Visited")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(country == nil)
                
                Divider()
                    .padding(.leading)
                
                Button {
                    if let country = country {
                        onViewDetails(country)
                    }
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        
                        Text("View Details")
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(country == nil)
            }
            
            Spacer()
        }
        .task {
            await loadCountry()
        }
    }
    
    private func loadCountry() async {
        // Load countries on background thread
        let countries = await Task.detached(priority: .userInitiated) {
            CountryDataService.shared.loadCountries()
        }.value
        
        // Find matching country
        country = countries.first { $0.id == countryID }
        isLoading = false
    }
    
    private func toggleVisited() {
        let newState = !isVisited
        appState.setVisited(countryID, isVisited: newState)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Dismiss after a short delay to show the state change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

