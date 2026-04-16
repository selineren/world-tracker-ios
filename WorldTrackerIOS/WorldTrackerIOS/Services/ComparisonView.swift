//
//  ComparisonView.swift
//  WorldTrackerIOS
//
//  Created by seren on 13.04.2026.
//

import SwiftUI
import Combine
import FirebaseAuth

struct ComparisonView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = ComparisonViewModel()
    @State private var displayMode: DisplayMode = .list
    @State private var mapZoomLevel: MapZoomLevel = .continent
    @State private var lastUserId: String? = nil
    
    enum DisplayMode {
        case list
        case map
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    searchView
                case .loading:
                    loadingView
                case .loaded:
                    resultsView
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Travel Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Check if user has changed (sign out / sign in / account switch)
                let currentUserId = authService.user?.uid
                
                if lastUserId != currentUserId {
                    // User changed - reset to idle state
                    lastUserId = currentUserId
                    viewModel.resetToIdle()
                }
            }
            .onChange(of: appState.visits) { _, newVisits in
                // Only reload if we have a comparison loaded
                if case .loaded = viewModel.state {
                    viewModel.reloadComparison(yourVisits: newVisits)
                }
            }
        }
    }
    
    // MARK: - State Views
    
    /// Initial state: Search for a user to compare with
    private var searchView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                
                Text("Compare Travel Experiences")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enter a friend's email to see how your travels compare")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)
            
            // Search field
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                    
                    TextField("friend@example.com", text: $viewModel.emailToCompare)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await viewModel.searchUser(yourVisits: appState.visits)
                            }
                        }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button {
                    Task {
                        await viewModel.searchUser(yourVisits: appState.visits)
                    }
                } label: {
                    Text("Compare")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.emailToCompare.isEmpty)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Privacy note
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("Privacy Protected")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                
                Text("You can only compare with users who have enabled comparison in their account settings")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)
        }
    }
    
    /// Loading state: Fetching user data
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading comparison...")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top)
            
            Spacer()
        }
    }
    
    /// Error state: Something went wrong
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
            
            Text("Unable to Compare")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                viewModel.resetToIdle()
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            
            Spacer()
        }
    }
    
    /// Loaded state: Show comparison results
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Compared user info bar
            if let profile = viewModel.comparedUserProfile {
                comparedUserInfoBar(profile: profile)
            }
            
            // Display Mode Picker (List vs Map)
            Picker("Display Mode", selection: $displayMode) {
                Text("List").tag(DisplayMode.list)
                Text("Map").tag(DisplayMode.map)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Mode Picker (Visited vs Wishlist)
            Picker("Comparison Mode", selection: $viewModel.selectedMode) {
                Text("Visited").tag(ComparisonMode.visited)
                Text("Wishlist").tag(ComparisonMode.wishlist)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on display mode
            if displayMode == .list {
                listView
            } else {
                mapView
            }
        }
    }
    
    /// Info bar showing who we're comparing with
    private func comparedUserInfoBar(profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Comparing with")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(profile.email)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Button {
                viewModel.resetToIdle()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
    
    // MARK: - List View
    
    private var listView: some View {
        VStack(spacing: 0) {
            // Stats Summary Card
            statsCard
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Main Comparison List
            List {
                // Section 1: Yours
                if !viewModel.currentComparison.yours.isEmpty {
                    Section {
                        ForEach(viewModel.yourCountries, id: \.id) { country in
                            CountryRow(country: country, badge: .yours)
                        }
                    } header: {
                        Text("Only You (\(viewModel.currentComparison.yours.count))")
                    }
                }
                
                // Section 2: Shared
                if !viewModel.currentComparison.shared.isEmpty {
                    Section {
                        ForEach(viewModel.sharedCountries, id: \.id) { country in
                            CountryRow(country: country, badge: .shared)
                        }
                    } header: {
                        Text("Both (\(viewModel.currentComparison.shared.count))")
                    }
                }
                
                // Section 3: Theirs
                if !viewModel.currentComparison.theirs.isEmpty {
                    Section {
                        ForEach(viewModel.theirCountries, id: \.id) { country in
                            CountryRow(country: country, badge: .theirs)
                        }
                    } header: {
                        Text("Only Them (\(viewModel.currentComparison.theirs.count))")
                    }
                }
                
                // Empty state
                if viewModel.currentComparison.totalUnique == 0 {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No data to compare")
                                .font(.headline)
                            Text("Mark some countries as \(viewModel.selectedMode == .visited ? "visited" : "wishlisted") to see the comparison")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        VStack(spacing: 0) {
            // Stats Summary Card
            statsCard
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Map Legend
            mapLegend
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Map
            ComparisonMapView(
                comparison: viewModel.currentComparison,
                zoomLevel: $mapZoomLevel,
                onCountryTapped: { countryId in
                    print("Tapped country: \(countryId)")
                }
            )
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Overlap",
                    value: "\(Int(viewModel.currentComparison.overlapPercentage))%",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    title: "Total Unique",
                    value: "\(viewModel.currentComparison.totalUnique)",
                    color: .purple
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    title: "Shared",
                    value: "\(viewModel.currentComparison.shared.count)",
                    color: .green
                )
            }
            .padding()
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Map Legend
    
    private var mapLegend: some View {
        HStack(spacing: 16) {
            LegendItem(color: .green, label: "Both", count: viewModel.currentComparison.shared.count)
            LegendItem(color: .blue, label: "You", count: viewModel.currentComparison.yours.count)
            LegendItem(color: .orange, label: "Them", count: viewModel.currentComparison.theirs.count)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
            Text("(\(count))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CountryRow: View {
    let country: Country
    let badge: ComparisonBadge
    
    var body: some View {
        HStack(spacing: 12) {
            Text(country.flagEmoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .font(.body)
                Text(country.continent.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            badge.icon
                .font(.caption)
                .foregroundStyle(badge.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badge.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Badge Type

enum ComparisonBadge {
    case yours
    case shared
    case theirs
    
    var icon: some View {
        switch self {
        case .yours:
            return Image(systemName: "person.fill")
        case .shared:
            return Image(systemName: "person.2.fill")
        case .theirs:
            return Image(systemName: "person.fill")
        }
    }
    
    var color: Color {
        switch self {
        case .yours:
            return .blue
        case .shared:
            return .green
        case .theirs:
            return .orange
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ComparisonViewModel: ObservableObject {
    // MARK: - State Management
    
    enum ViewState: Equatable {
        case idle                    // Initial state - show search UI
        case loading                 // Fetching user data
        case loaded                  // Comparison data loaded successfully
        case error(String)          // Error occurred
    }
    
    @Published var state: ViewState = .idle
    @Published var selectedMode: ComparisonMode = .visited
    @Published var emailToCompare: String = ""
    @Published private(set) var comparedUserProfile: UserProfile?
    
    // Comparison results (only populated in .loaded state)
    @Published private(set) var visitedComparison: TravelComparisonResult
    @Published private(set) var wishlistComparison: TravelComparisonResult
    
    // Services and data
    private let countryService = CountryDataService.shared
    private let profileRepository = FirestoreUserRepository()
    private let visitRepository = FirestoreVisitRepository()
    private var allCountries: [Country] = []
    
    // Current comparison based on selected mode
    var currentComparison: TravelComparisonResult {
        selectedMode == .visited ? visitedComparison : wishlistComparison
    }
    
    // Convert country IDs to Country objects
    var yourCountries: [Country] {
        getCountries(for: Array(currentComparison.yours))
    }
    
    var sharedCountries: [Country] {
        getCountries(for: Array(currentComparison.shared))
    }
    
    var theirCountries: [Country] {
        getCountries(for: Array(currentComparison.theirs))
    }
    
    init() {
        // Initialize with empty comparisons
        self.visitedComparison = TravelComparisonResult(
            yours: [],
            shared: [],
            theirs: [],
            mode: .visited
        )
        self.wishlistComparison = TravelComparisonResult(
            yours: [],
            shared: [],
            theirs: [],
            mode: .wishlist
        )
        
        // Load countries
        self.allCountries = countryService.loadCountries()
    }
    
    // MARK: - Public Methods
    
    /// Search for a user by email and load their comparison data
    func searchUser(yourVisits: [String: Visit]) async {
        state = .loading
        
        // Create a timeout task (8 seconds like in AccountScreen)
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000) // 8 seconds
            if case .loading = state {
                state = .error("Request timed out. Please check your internet connection and try again.")
                
                #if DEBUG
                print("⏱️ Search operation timed out after 8 seconds")
                #endif
            }
        }
        
        defer {
            timeoutTask.cancel()
        }
        
        do {
            // Step 1: Find the profile by email
            let profile: UserProfile?
            do {
                profile = try await profileRepository.findProfileByEmail(emailToCompare)
            } catch {
                // Cancel timeout before handling error
                timeoutTask.cancel()
                
                // Network error occurred during profile lookup
                let errorMessage = userFriendlyErrorMessage(from: error)
                state = .error(errorMessage)
                
                #if DEBUG
                print("❌ Network error during profile lookup: \(error)")
                #endif
                return
            }
            
            // Check if profile was found
            guard let profile else {
                timeoutTask.cancel()
                state = .error("User not found or they have disabled comparison in their privacy settings")
                return
            }
            
            #if DEBUG
            print("✅ Found user profile: \(profile.email)")
            #endif
            
            // Step 2: Fetch their visits
            let theirVisitsArray = try await visitRepository.allVisits(forUserId: profile.id)
            
            #if DEBUG
            print("✅ Fetched \(theirVisitsArray.count) visits for user \(profile.email)")
            #endif
            
            // Step 3: Convert to dictionary for comparison engine
            let theirVisitsDict = Dictionary(uniqueKeysWithValues: theirVisitsArray.map { ($0.countryId, $0) })
            
            // Step 4: Perform comparisons
            visitedComparison = TravelComparisonEngine.compare(
                yourVisits: yourVisits,
                theirVisits: theirVisitsDict,
                mode: .visited
            )
            
            wishlistComparison = TravelComparisonEngine.compare(
                yourVisits: yourVisits,
                theirVisits: theirVisitsDict,
                mode: .wishlist
            )
            
            // Step 5: Update state
            comparedUserProfile = profile
            state = .loaded
            
            // Cancel timeout on success
            timeoutTask.cancel()
            
        } catch {
            // Cancel timeout before handling error
            timeoutTask.cancel()
            
            // Detect and handle network errors specifically
            let errorMessage = userFriendlyErrorMessage(from: error)
            state = .error(errorMessage)
            
            #if DEBUG
            print("❌ Failed to fetch visits: \(error)")
            #endif
        }
    }
    
    /// Reload the comparison with updated visit data (called when user's visits change)
    func reloadComparison(yourVisits: [String: Visit]) {
        guard case .loaded = state, let profile = comparedUserProfile else { return }
        
        // Re-fetch the other user's visits and re-compare
        Task {
            do {
                let theirVisitsArray = try await visitRepository.allVisits(forUserId: profile.id)
                let theirVisitsDict = Dictionary(uniqueKeysWithValues: theirVisitsArray.map { ($0.countryId, $0) })
                
                // Perform comparisons
                visitedComparison = TravelComparisonEngine.compare(
                    yourVisits: yourVisits,
                    theirVisits: theirVisitsDict,
                    mode: .visited
                )
                
                wishlistComparison = TravelComparisonEngine.compare(
                    yourVisits: yourVisits,
                    theirVisits: theirVisitsDict,
                    mode: .wishlist
                )
                
                #if DEBUG
                print("✅ Reloaded comparison with updated data")
                #endif
                
            } catch {
                #if DEBUG
                print("⚠️ Failed to reload comparison: \(error)")
                #endif
                // Don't change state - keep showing old data
            }
        }
    }
    
    /// Reset to idle state (ready to search for a new user)
    func resetToIdle() {
        state = .idle
        emailToCompare = ""
        comparedUserProfile = nil
        
        // Clear comparison data
        visitedComparison = TravelComparisonResult(
            yours: [],
            shared: [],
            theirs: [],
            mode: .visited
        )
        wishlistComparison = TravelComparisonResult(
            yours: [],
            shared: [],
            theirs: [],
            mode: .wishlist
        )
    }
    
    // MARK: - Error Handling
    
    /// Convert errors into user-friendly messages, detecting network issues
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        // Check for network-related error codes
        // NSURLErrorDomain codes: https://developer.apple.com/documentation/foundation/nsurlerrordomain
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection. Please check your network and try again."
            case NSURLErrorNetworkConnectionLost:
                return "Network connection was lost. Please try again."
            case NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost:
                return "Unable to connect to server. Please check your internet connection."
            case NSURLErrorTimedOut:
                return "Connection timed out. Please try again."
            case NSURLErrorDNSLookupFailed:
                return "Network error: DNS lookup failed. Please check your connection."
            default:
                return "Network error. Please check your connection and try again."
            }
        }
        
        // Check for Firebase-specific network errors
        // Firebase Firestore error domain
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 14: // UNAVAILABLE - network issue or server unavailable
                return "Unable to connect to the server. Please check your internet connection and try again."
            case 4: // DEADLINE_EXCEEDED - operation timeout
                return "Request timed out. Please check your connection and try again."
            case 7: // PERMISSION_DENIED
                return "Permission denied. The user may have changed their privacy settings."
            default:
                break
            }
        }
        
        // Default error message with original description
        return "Failed to load user: \(error.localizedDescription)"
    }
    
    // MARK: - Helpers
    
    private func getCountries(for countryIds: [String]) -> [Country] {
        let countryDict = Dictionary(uniqueKeysWithValues: allCountries.map { ($0.id, $0) })
        return countryIds.compactMap { countryDict[$0] }.sorted { $0.name < $1.name }
    }
}

// MARK: - Preview

#Preview {
    ComparisonView()
}
