//
//  TravelComparisonExample.swift
//  WorldTrackerIOS
//
//  Created by seren on 13.04.2026.
//
//  This file demonstrates how to use TravelComparisonEngine
//  with existing AppState data. NOT meant to be compiled - just documentation.
//

/*

// MARK: - Example 1: Simple Visited Comparison

func compareVisitedCountries(with friendVisits: [String: Visit]) {
    // Get your visits from AppState (already loaded)
    let yourVisits = appState.visits
    
    // Compare visited countries
    let comparison = TravelComparisonEngine.compare(
        yourVisits: yourVisits,
        theirVisits: friendVisits,
        mode: .visited
    )
    
    // Use the results
    print("You visited \(comparison.yours.count) unique countries")
    print("They visited \(comparison.theirs.count) unique countries")
    print("You both visited \(comparison.shared.count) countries")
    print("Overlap: \(comparison.overlapPercentage)%")
    
    // Example: Display shared countries
    for countryId in comparison.shared {
        print("Both visited: \(countryId)")
    }
}

// MARK: - Example 2: Wishlist Comparison

func compareWishlists(with friendVisits: [String: Visit]) {
    let comparison = TravelComparisonEngine.compare(
        yourVisits: appState.visits,
        theirVisits: friendVisits,
        mode: .wishlist
    )
    
    print("Shared dream destinations: \(comparison.shared)")
}

// MARK: - Example 3: Full Comparison (Both Modes)

func performFullComparison(with friendVisits: [String: Visit]) {
    let detailed = TravelComparisonEngine.detailedCompare(
        yourVisits: appState.visits,
        theirVisits: friendVisits
    )
    
    // Visited stats
    let visited = detailed.visitedComparison
    print("=== Visited Countries ===")
    print("Only you: \(visited.yours.count)")
    print("Both: \(visited.shared.count)")
    print("Only them: \(visited.theirs.count)")
    
    // Wishlist stats
    let wishlist = detailed.wishlistComparison
    print("\n=== Wishlist ===")
    print("Only you: \(wishlist.yours.count)")
    print("Both: \(wishlist.shared.count)")
    print("Only them: \(wishlist.theirs.count)")
    
    // Interesting insights
    let conflicts = detailed.conflictingCountries
    if conflicts.hasConflicts {
        print("\n=== Travel Advice Opportunities ===")
        print("You've been where they want to go: \(conflicts.youVisitedTheyWishlisted)")
        print("They've been where you want to go: \(conflicts.theyVisitedYouWishlisted)")
    }
    
    print("\nTotal unique countries: \(detailed.totalUniqueCountries)")
}

// MARK: - Example 4: Using with Arrays (from Firestore)

func compareWithFetchedData(friendUserId: String) async throws {
    // Fetch friend's visits (from Firestore, future implementation)
    // let friendVisits = try await fetchVisitsForUser(friendUserId)
    
    // Convert your AppState visits to array if needed
    let yourVisitsArray = Array(appState.visits.values)
    
    // Assuming friendVisits is [Visit]
    // let comparison = TravelComparisonEngine.compare(
    //     yourVisits: yourVisitsArray,
    //     theirVisits: friendVisits,
    //     mode: .visited
    // )
}

// MARK: - Example 5: Check Individual Country Ownership

func checkCountryOwnership(countryId: String, friendVisits: [String: Visit]) {
    let comparison = TravelComparisonEngine.compare(
        yourVisits: appState.visits,
        theirVisits: friendVisits,
        mode: .visited
    )
    
    if comparison.isShared(countryId) {
        print("\(countryId): Both of you have visited!")
    } else if comparison.isYours(countryId) {
        print("\(countryId): Only you have visited")
    } else if comparison.isTheirs(countryId) {
        print("\(countryId): Only they have visited")
    } else {
        print("\(countryId): Neither has visited")
    }
    
    // Or use the ownership enum
    switch comparison.ownership(of: countryId) {
    case .yours:
        print("Your exclusive destination")
    case .shared:
        print("Shared experience")
    case .theirs:
        print("Their exclusive destination")
    case nil:
        print("Not in comparison")
    }
}

// MARK: - Example 6: Integration with Future UI

// This is how a ViewModel might use it:
@MainActor
class ComparisonViewModel: ObservableObject {
    @Published var comparison: DetailedTravelComparison?
    @Published var isLoading = false
    
    func loadComparison(friendEmail: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Step 1: Fetch friend's data (not implemented yet)
        // let friendVisits = try await fetchFriendVisits(email: friendEmail)
        
        // Step 2: Compare (already implemented!)
        // let result = TravelComparisonEngine.detailedCompare(
        //     yourVisits: appState.visits,
        //     theirVisits: friendVisits
        // )
        
        // Step 3: Store result
        // self.comparison = result
    }
}

*/
