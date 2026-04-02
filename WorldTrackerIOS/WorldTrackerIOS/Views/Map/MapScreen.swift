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
    @State private var selectedCountryForSheet: SelectedCountry?
    @State private var selectedCountryForDetail: Country?
    @State private var mapZoomLevel: MapZoomLevel = .continent
    @State private var showingStats = true
    @State private var expandedCountryPreview: CountryPreviewData?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // OPTIMIZATION: Isolate map in separate view to prevent parent re-renders
                MapContainerView(
                    visitedCountryIDs: appState.visitedCountryIDs,
                    wantToVisitCountryIDs: appState.wantToVisitCountryIDs,
                    zoomLevel: $mapZoomLevel,
                    bitmojiAnnotations: getBitmojiAnnotations(),
                    onCountryTapped: { countryID in
                        handleCountryTap(countryID: countryID)
                    },
                    onBitmojiTapped: { countryID in
                        handleBitmojiTap(countryID: countryID)
                    }
                )
                .edgesIgnoringSafeArea(.top)
                
                // Overlay UI Elements - Left side
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
                
                // Zoom Controls (right side)
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        zoomControls
                            .padding(.trailing, 16)
                            .padding(.bottom, 20)
                    }
                }
                .padding(.top, 100) // Avoid overlap with navigation bar
                
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
                
                // Expanded preview bubble (when tapping a bitmoji)
                if let preview = expandedCountryPreview {
                    ZStack {
                        // Tap outside to dismiss
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    expandedCountryPreview = nil
                                }
                            }
                        
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                CountryMapPreviewBubble(
                                    country: preview.country,
                                    visit: preview.visit,
                                    onDismiss: {
                                        expandedCountryPreview = nil
                                    },
                                    onViewDetails: {
                                        selectedCountryForDetail = preview.country
                                        expandedCountryPreview = nil
                                    }
                                )
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                            // Prevent tap from passing through to the background
                            .onTapGesture { }
                        }
                    }
                    .transition(.opacity)
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
            .sheet(item: $selectedCountryForSheet) { selectedCountry in
                CountryQuickActionSheet(
                    countryID: selectedCountry.id,
                    appState: appState,
                    onViewDetails: { country in
                        selectedCountryForDetail = country
                        selectedCountryForSheet = nil
                    }
                )
                .presentationDetents([.height(340), .medium])
                .presentationDragIndicator(.visible)
            }
            .navigationDestination(item: $selectedCountryForDetail) { country in
                CountryDetailScreen(country: country)
            }
        }
    }
    
    // MARK: - Zoom Controls
    
    private var zoomControls: some View {
        VStack(spacing: 1) {
            // Zoom In Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    zoomIn()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .contentShape(Rectangle())
            }
            .disabled(!canZoomIn)
            .opacity(canZoomIn ? 1 : 0.5)
            
            Divider()
                .frame(width: 44)
            
            // Zoom Out Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    zoomOut()
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .contentShape(Rectangle())
            }
            .disabled(!canZoomOut)
            .opacity(canZoomOut ? 1 : 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
    
    private var canZoomIn: Bool {
        mapZoomLevel != .max
    }
    
    private var canZoomOut: Bool {
        mapZoomLevel != .world
    }
    
    private func zoomIn() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        switch mapZoomLevel {
        case .world:
            mapZoomLevel = .continent
        case .continent:
            mapZoomLevel = .country
        case .country:
            mapZoomLevel = .city
        case .city:
            mapZoomLevel = .max
        case .max:
            break
        }
    }
    
    private func zoomOut() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        switch mapZoomLevel {
        case .max:
            mapZoomLevel = .city
        case .city:
            mapZoomLevel = .country
        case .country:
            mapZoomLevel = .continent
        case .continent:
            mapZoomLevel = .world
        case .world:
            break
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
    
    private func handleCountryTap(countryID: String) {
        // Close any expanded preview first
        expandedCountryPreview = nil
        
        // Always show quick action sheet (for both visited and unvisited)
        selectedCountryForSheet = SelectedCountry(id: countryID)
    }
    
    private func handleBitmojiTap(countryID: String) {
        // Close any open quick action sheet first
        selectedCountryForSheet = nil
        
        // Show expanded preview when tapping a bitmoji
        let countries = CountryDataService.shared.loadCountries()
        guard let country = countries.first(where: { $0.id == countryID }) else {
            return
        }
        
        let visit = appState.visit(for: countryID)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            expandedCountryPreview = CountryPreviewData(country: country, visit: visit)
        }
    }
    
    private func getBitmojiAnnotations() -> [CountryBitmojiAnnotation] {
        // Only show bitmojis at continent zoom or closer to avoid clutter
        guard mapZoomLevel != .world else {
            return []
        }
        
        let countries = CountryDataService.shared.loadCountries()
        
        let annotations: [CountryBitmojiAnnotation] = appState.visitedCountryIDs.compactMap { countryID -> CountryBitmojiAnnotation? in
            guard let country = countries.first(where: { $0.id == countryID }) else {
                return nil
            }
            
            let visit = appState.visit(for: countryID)
            return CountryBitmojiAnnotation(country: country, visit: visit)
        }
        
        return annotations
    }
    
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

// MARK: - Map Zoom Level

struct SelectedCountry: Identifiable {
    let id: String
}

enum MapZoomLevel: Equatable {
    case world      // Global view (120° span)
    case continent  // Continental view (60° span)
    case country    // Country view (20° span)
    case city       // City view (5° span)
    case max        // Maximum zoom (1° span)
    
    var latitudeDelta: CLLocationDegrees {
        switch self {
        case .world:
            return 120
        case .continent:
            return 60
        case .country:
            return 20
        case .city:
            return 5
        case .max:
            return 1
        }
    }
    
    var longitudeDelta: CLLocationDegrees {
        return latitudeDelta
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
    
    private var wantToVisit: Bool {
        appState.wantToVisit(countryID)
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
                    toggleWantToVisit()
                } label: {
                    HStack {
                        Image(systemName: wantToVisit ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(wantToVisit ? .orange : .gray)
                        
                        Text(wantToVisit ? "Remove from Wishlist" : "Want to Visit")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isVisited || country == nil)
                
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
        // Load countries (happens on main actor)
        let countries = CountryDataService.shared.loadCountries()
        
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
    
    private func toggleWantToVisit() {
        let newState = !wantToVisit
        appState.setWantToVisit(countryID, wantToVisit: newState)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Dismiss after a short delay to show the state change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Map Container (Optimization)
/// Isolated map container to prevent unnecessary re-renders from parent view state changes
struct MapContainerView: View {
    let visitedCountryIDs: Set<String>
    let wantToVisitCountryIDs: Set<String>
    @Binding var zoomLevel: MapZoomLevel
    let bitmojiAnnotations: [CountryBitmojiAnnotation]
    let onCountryTapped: ((String) -> Void)?
    let onBitmojiTapped: ((String) -> Void)?
    
    var body: some View {
        VisitedCountriesMapView(
            visitedCountryIDs: visitedCountryIDs,
            wantToVisitCountryIDs: wantToVisitCountryIDs,
            zoomLevel: $zoomLevel,
            onCountryTapped: onCountryTapped,
            bitmojiAnnotations: bitmojiAnnotations,
            onBitmojiTapped: onBitmojiTapped
        )
    }
}


