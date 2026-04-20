//
//  StatsScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI
import Combine

struct StatsScreen: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = StatsViewModel()
    
    init() {
        #if DEBUG
        print("🎨 StatsScreen initialized")
        #endif
    }
    
    // MARK: - Computed stats
    
    private var visitedVisits: [Visit] {
        appState.visits.values
            .filter { $0.isVisited }
    }
    
    private var wantToVisitVisits: [Visit] {
        appState.visits.values
            .filter { $0.wantToVisit }
    }
    
    private var totalCountriesCount: Int {
        vm.countries.count
    }
    
    private var visitedCountriesCount: Int {
        visitedVisits.count
    }
    
    private var wantToVisitCount: Int {
        wantToVisitVisits.count
    }

    private var totalPhotosCount: Int {
        visitedVisits.reduce(0) { $0 + $1.photos.count }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var visitedPercentage: Double {
        guard totalCountriesCount > 0 else { return 0 }
        return Double(visitedCountriesCount) / Double(totalCountriesCount) * 100
    }
    
    private var achievements: [Achievement] {
        vm.achievements(from: appState.visits)
    }
    
    private var achievementSummary: (total: Int, unlocked: Int) {
        AchievementEngine.achievementSummary(achievements)
    }
    
    private var visitedCountries: [Country] {
        let visitedIDs = Set(visitedVisits.map { $0.countryId })
        return vm.countries.filter { visitedIDs.contains($0.id) }
    }
    
    private var wantToVisitCountries: [Country] {
        let wantToVisitIDs = Set(wantToVisitVisits.map { $0.countryId })
        return vm.countries.filter { wantToVisitIDs.contains($0.id) }
    }
    
    private var visitedThisYear: [(country: Country, date: Date)] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let byId = Dictionary(uniqueKeysWithValues: vm.countries.map { ($0.id, $0) })
        
        return visitedVisits
            .compactMap { visit -> (country: Country, date: Date)? in
                // Get country first
                guard let country = byId[visit.countryId] else {
                    return nil
                }
                
                // For visited countries, use visitedDate (should always exist for visited)
                // If somehow missing, fall back to updatedAt to avoid losing the data
                guard let date = visit.visitedDate ?? (visit.isVisited ? visit.updatedAt : nil) else {
                    return nil
                }
                
                // Check if the date is in the current year
                guard calendar.component(.year, from: date) == currentYear else {
                    return nil
                }
                
                return (country: country, date: date)
            }
            .sorted { $0.date > $1.date }
    }
    
    private var visitedByContinent: [(continent: Continent, visited: Int, wantToVisit: Int, total: Int, percentage: Double)] {
        let grouped = Dictionary(grouping: vm.countries, by: { $0.continent })
        
        return Continent.allCases.map { continent in
            let all = grouped[continent] ?? []
            let visitedIDs = Set(visitedVisits.map { $0.countryId })
            let wantToVisitIDs = Set(wantToVisitVisits.map { $0.countryId })
            let visited = all.filter { visitedIDs.contains($0.id) }.count
            let wantToVisit = all.filter { wantToVisitIDs.contains($0.id) }.count
            let percentage = all.count > 0 ? Double(visited) / Double(all.count) * 100 : 0
            return (continent: continent, visited: visited, wantToVisit: wantToVisit, total: all.count, percentage: percentage)
        }
        .filter { $0.total > 0 }
        .sorted { $0.percentage > $1.percentage }
    }
    
    private var recentVisits: [(country: Country, date: Date?)] {
        let byId = Dictionary(uniqueKeysWithValues: vm.countries.map { ($0.id, $0) })
        
        return visitedVisits
            .compactMap { visit in
                guard let country = byId[visit.countryId] else { return nil }
                return (country: country, date: visit.visitedDate)
            }
            .sorted {
                // visits with date first, newest first
                switch ($0.date, $1.date) {
                case let (d0?, d1?):
                    return d0 > d1
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    return $0.country.name < $1.country.name
                }
            }
    }
    
    // MARK: - Design system views

    private var continentsVisitedCount: Int {
        visitedByContinent.filter { $0.visited > 0 }.count
    }

    private var statsHeader: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your journey").eyebrowStyle()
                HStack(spacing: 0) {
                    Text("The ")
                        .font(.system(size: 44, weight: .regular, design: .serif))
                        .foregroundStyle(Color.appInk)
                    Text("numbers")
                        .font(AppTypography.displayLarge)
                        .foregroundStyle(Color.appSky)
                }
            }

            // Confetti decorations
            Circle().fill(Color.appRose).frame(width: 9, height: 9)
                .offset(x: 212, y: 8)
            Text("▶")
                .font(.system(size: 11, weight: .bold)).foregroundStyle(Color.appLime)
                .offset(x: 178, y: 52)
            Text("★")
                .font(.system(size: 18)).foregroundStyle(Color.appSunset)
                .offset(x: 228, y: 60)
            ConfettiWave()
                .stroke(Color.appRose, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 28, height: 20)
                .offset(x: 244, y: 22)
            Text("◀")
                .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.appInk)
                .offset(x: 272, y: 74)
            Text("★")
                .font(.system(size: 12)).foregroundStyle(Color.appLime)
                .offset(x: 213, y: 108)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("You've explored")
                .font(AppTypography.eyebrow)
                .fontWeight(.bold)
                .tracking(2.0)
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.82))
                .padding(.bottom, 6)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(visitedCountriesCount)")
                    .font(AppTypography.displayHero)
                    .foregroundStyle(Color.white)

                Text("of \(totalCountriesCount)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .padding(.bottom, 8)

            Text("\(visitedPercentage, specifier: "%.1f")% of the world · \(continentsVisitedCount) continents")
                .font(AppTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            ZStack(alignment: .bottomTrailing) {
                Color.appRose
                Text("\(Int(visitedPercentage))%")
                    .font(AppTypography.displayHero)
                    .italic()
                    .foregroundStyle(Color.white.opacity(0.09))
                    .padding(.trailing, -12)
                    .padding(.bottom, -28)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.appRose.opacity(0.32), radius: 28, x: 0, y: 10)
    }

    // MARK: - UI

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    // MARK: - Stats Header + Hero Card + Mini Stats
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            statsHeader
                                .padding(.horizontal, 16)
                            heroCard
                                .padding(.horizontal, 16)
                                .padding(.bottom, 14)
                            HStack(spacing: 10) {
                                MiniStatCard(
                                    value: "\(visitedThisYear.count)",
                                    label: "in \(currentYear)",
                                    background: Color.appLime,
                                    foreground: Color.appInk
                                )
                                MiniStatCard(
                                    value: "\(wantToVisitCount)",
                                    label: "on wishlist",
                                    background: Color.appAqua,
                                    foreground: Color.appInk
                                )
                                MiniStatCard(
                                    value: "\(totalPhotosCount)",
                                    label: "photos",
                                    background: Color.appSunset,
                                    foreground: .white
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 24)
                        .listRowBackground(Color.appPaper)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    
                    // MARK: - Badges
                    Section {
                        Text("Badges").eyebrowStyle()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .listRowBackground(Color.appPaper)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(achievements) { achievement in
                                    AchievementCard(achievement: achievement)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                        }
                        .listRowBackground(Color.appPaper)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }

                    // MARK: - Travel Wishlist
                    if !wantToVisitCountries.isEmpty {
                        Section {
                            Text("Travel Wishlist").eyebrowStyle()
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .listRowBackground(Color.appPaper)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(wantToVisitCountries) { country in
                                        NavigationLink {
                                            CountryDetailScreen(country: country)
                                        } label: {
                                            VStack(spacing: 4) {
                                                ZStack(alignment: .topTrailing) {
                                                    Text(country.flagEmoji)
                                                        .font(.system(size: 32))
                                                    Image(systemName: "star.fill")
                                                        .font(.caption2)
                                                        .foregroundStyle(.orange)
                                                        .offset(x: 4, y: -4)
                                                }
                                                Text(country.name)
                                                    .font(.caption2)
                                                    .lineLimit(1)
                                                    .frame(width: 70)
                                            }
                                            .padding(8)
                                            .background(.thinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.appPaper)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        }
                    }

                    // MARK: - Visited by Continent
                    Section {
                        Text("Progress by Continent").eyebrowStyle()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .listRowBackground(Color.appPaper)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12),
                                      GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(visitedByContinent, id: \.continent.id) { item in
                                let accent = continentAccent(for: item.continent)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(item.continent.displayName)
                                        .font(AppTypography.displaySmall)
                                        .foregroundStyle(Color.appInk)
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("\(item.visited)")
                                            .font(AppTypography.statLarge)
                                            .foregroundStyle(Color.appInk)
                                        Text("/ \(item.total)")
                                            .font(AppTypography.bodySmall)
                                            .foregroundStyle(Color.appInk3)
                                    }
                                    continentDots(visited: item.visited, total: item.total, accent: accent)
                                }
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(14)
                                .background(accent.opacity(0.13))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .aspectRatio(1, contentMode: .fit)
                            }
                        }
                        .listRowBackground(Color.appPaper)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }

                    // MARK: - Visited Countries
                    if !visitedCountries.isEmpty {
                        Section {
                            Text("Visited Countries").eyebrowStyle()
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .listRowBackground(Color.appPaper)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(visitedCountries.enumerated()), id: \.element.id) { index, country in
                                        let chipColors: [Color] = [.appRose, .appSky, .appLime, .appSunset, .appAqua, .appBlush]
                                        let accent = chipColors[index % chipColors.count]
                                        NavigationLink {
                                            CountryDetailScreen(country: country)
                                        } label: {
                                            HStack(spacing: 7) {
                                                Text(country.flagEmoji)
                                                    .font(.system(size: 22))
                                                Text(country.name)
                                                    .font(AppTypography.bodySmall)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(Color.appInk)
                                                    .lineLimit(1)
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 14)
                                            .frame(maxWidth: 160)
                                            .background(Color.appCard)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(accent, lineWidth: 2))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                            }
                            .listRowBackground(Color.appPaper)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        }
                    }

                    // MARK: - Fresh Memories
                    if !recentVisits.isEmpty {
                        Section {
                            Text("Fresh Memories").eyebrowStyle()
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .listRowBackground(Color.appPaper)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                            ForEach(
                                Array(recentVisits.prefix(8).enumerated()),
                                id: \.element.country.id
                            ) { index, item in
                                ZStack(alignment: .trailing) {
                                    NavigationLink {
                                        CountryDetailScreen(country: item.country)
                                    } label: { EmptyView() }
                                        .opacity(0)
                                    HStack(spacing: 12) {
                                        Text(item.country.flagEmoji)
                                            .font(.system(size: 28))
                                            .frame(width: 48, height: 48)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(color: Color.appInk.opacity(0.07), radius: 4, x: 0, y: 2)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.country.name)
                                                .font(AppTypography.displaySmall)
                                                .foregroundStyle(Color.appInk)
                                            HStack(spacing: 4) {
                                                Text(formattedDate(item.date))
                                                    .foregroundStyle(memoryCardAccent(at: index))
                                                let photos = photoCount(for: item.country.id)
                                                if photos > 0 {
                                                    Text("·")
                                                        .foregroundStyle(Color.appInk3)
                                                    Text("\(photos) photos")
                                                        .foregroundStyle(Color.appInk3)
                                                }
                                            }
                                            .font(AppTypography.bodySmall)
                                            .fontWeight(.medium)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.appInk3)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(14)
                                .background(memoryCardBG(at: index))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .listRowBackground(Color.appPaper)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }
                    }

                }
                .scrollContentBackground(.hidden)

                // Loading overlay (unchanged)
                if vm.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading statistics...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
                }
            }
            .background(Color.appPaper)
            .toolbar(.hidden, for: .navigationBar)
            .listStyle(.plain)
        }
    }
    
    // MARK: - Helper Methods
    
    private func continentColor(for percentage: Double) -> Color {
        switch percentage {
        case 75...:
            return .green
        case 50..<75:
            return .blue
        case 25..<50:
            return .orange
        default:
            return .red
        }
    }

    private func continentAccent(for continent: Continent) -> Color {
        switch continent {
        case .africa:       return .appSunset
        case .antarctica:   return .appSky
        case .asia:         return .appRose
        case .europe:       return .appSky
        case .northAmerica: return .appLime
        case .oceania:      return .appSunset
        case .southAmerica: return .appRose
        }
    }
    
    private func photoCount(for countryId: String) -> Int {
        visitedVisits.first { $0.countryId == countryId }?.photos.count ?? 0
    }

    private func continentDots(visited: Int, total: Int, accent: Color) -> some View {
        let cols = Array(repeating: GridItem(.fixed(5), spacing: 3), count: 16)
        return LazyVGrid(columns: cols, alignment: .leading, spacing: 3) {
            ForEach(0..<min(total, 48), id: \.self) { i in
                Circle()
                    .fill(i < visited ? accent : accent.opacity(0.22))
                    .frame(width: 5, height: 5)
            }
        }
    }

    private func memoryCardBG(at index: Int) -> Color {
        switch index % 4 {
        case 0:  return .appAqua
        case 1:  return .appBlush
        case 2:  return .appLime.opacity(0.30)
        default: return .appSunset.opacity(0.22)
        }
    }

    private func memoryCardAccent(at index: Int) -> Color {
        switch index % 4 {
        case 0:  return .appSky
        case 1:  return .appRose
        case 2:  return .appLime
        default: return .appSunset
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Stats ViewModel
    
    @MainActor
    final class StatsViewModel: ObservableObject {
        @Published private(set) var countries: [Country] = []
        @Published private(set) var isLoading = false
        
        private let service = CountryDataService.shared
        
        init() {
            #if DEBUG
            print("📊 StatsViewModel initialized")
            #endif
            load()
        }
        
        func load() {
            #if DEBUG
            print("📊 StatsViewModel.load() called")
            #endif
            isLoading = true
            
            // Load countries
            Task(priority: .userInitiated) {
                #if DEBUG
                print("📊 About to call CountryDataService.loadCountries()")
                #endif
                let loadedCountries = service.loadCountries()
                #if DEBUG
                print("📊 Received \(loadedCountries.count) countries from service")
                #endif
                
                self.countries = loadedCountries
                self.isLoading = false
                #if DEBUG
                print("📊 Updated StatsViewModel with \(loadedCountries.count) countries")
                #endif
            }
        }
        
        // MARK: - Achievements
        
        /// Calculate achievements based on current visit data
        /// - Parameter visits: Dictionary of all visits from AppState
        /// - Returns: Array of achievements with unlock status
        func achievements(from visits: [String: Visit]) -> [Achievement] {
            return AchievementEngine.calculateAchievements(
                visits: visits,
                countries: countries
            )
        }
    }
    
    // MARK: - Supporting Views

    private struct ConfettiWave: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: 0, y: rect.midY))
            p.addCurve(
                to: CGPoint(x: rect.width / 2, y: rect.midY),
                control1: CGPoint(x: rect.width * 0.15, y: 0),
                control2: CGPoint(x: rect.width * 0.35, y: rect.height)
            )
            p.addCurve(
                to: CGPoint(x: rect.width, y: rect.midY),
                control1: CGPoint(x: rect.width * 0.65, y: 0),
                control2: CGPoint(x: rect.width * 0.85, y: rect.height)
            )
            return p
        }
    }

    private struct MiniStatCard: View {
        let value: String
        let label: String
        let background: Color
        let foreground: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AppTypography.statLarge)
                    .foregroundStyle(foreground)
                Spacer()
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(foreground.opacity(0.75))
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding(16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.appInk.opacity(0.06), radius: 8, x: 0, y: 3)
        }
    }
    
    private struct AchievementCard: View {
        let achievement: Achievement

        private var palette: (bg: Color, fg: Color) {
            guard achievement.isUnlocked else {
                return (bg: .appCard, fg: .appInk)
            }
            switch achievement.type {
            case .firstCountry:         return (bg: .appRose,   fg: .white)
            case .firstNote:            return (bg: .appBlush,  fg: .appInk)
            case .firstPhoto:           return (bg: .appAqua,   fg: .appInk)
            case .countries(let n):     return n <= 5
                                            ? (bg: .appLime,    fg: .appInk)
                                            : (bg: .appSunset,  fg: .white)
            case .continents:           return (bg: .appBlush,  fg: .appInk)
            case .allContinents:        return (bg: .appAqua,   fg: .appInk)
            }
        }

        private var shortLabel: String {
            switch achievement.type {
            case .firstCountry:         return "First Country"
            case .firstNote:            return "First Note"
            case .firstPhoto:           return "First Photo"
            case .countries(let n):     return "\(n) Countries"
            case .continents(let n):    return "\(n) Continents"
            case .allContinents:        return "All Continents"
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(achievement.isUnlocked ? "🏆" : "🔒")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 3) {
                    Text(shortLabel)
                        .font(AppTypography.displaySmall)
                        .foregroundStyle(palette.fg)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(achievement.isUnlocked ? "Unlocked" : "Locked")
                        .font(AppTypography.eyebrow)
                        .fontWeight(.bold)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(palette.fg.opacity(achievement.isUnlocked ? 0.82 : 0.45))
                }
            }
            .frame(width: 110, height: 110, alignment: .leading)
            .padding(13)
            .background(palette.bg)
            .overlay {
                if !achievement.isUnlocked {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.appLine, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(
                color: Color.appInk.opacity(achievement.isUnlocked ? 0.09 : 0.04),
                radius: achievement.isUnlocked ? 12 : 5,
                x: 0,
                y: achievement.isUnlocked ? 6 : 2
            )
            .opacity(achievement.isUnlocked ? 1.0 : 0.88)
        }
    }
}
// MARK: - Visited This Year List View

struct VisitedThisYearListView: View {
    let visits: [(country: Country, date: Date)]
    
    var body: some View {
        List {
            ForEach(visits, id: \.country.id) { item in
                NavigationLink {
                    CountryDetailScreen(country: item.country)
                } label: {
                    HStack(spacing: 12) {
                        Text(item.country.flagEmoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.country.name)
                                .font(.body)
                            Text(item.country.continent.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formattedDate(item.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Visited This Year")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

