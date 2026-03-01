# WorldTracker iOS

WorldTracker is an iOS application built with SwiftUI using a clean MVVM-based structure.

Phase 1 focuses on establishing the full UI architecture and application flow using mock data, ensuring a solid foundation before introducing persistence and networking.

---

# Phase 1 – UI Foundation (Dummy Data)

## Goal
Establish a clean MVVM structure and complete app navigation flow using mock data.

## Implemented Features

### Navigation
- Tab-based navigation (Map / Countries / Stats)
- NavigationStack-based detail flow

### Countries
- Countries list grouped by continent
- Search functionality
- Empty state when search returns no results
- Country detail screen

### Country Detail
- Toggle "Visited" state
- Custom visit date selection
- Editable notes
- Visited state reflected immediately in list

### State Management
- Centralized `AppState`
- In-memory visit tracking
- Reactive UI updates via `@EnvironmentObject`

### Stats
- Displays dynamic visited country count
- Placeholder layout for future statistics

### Map
- Phase 1 placeholder screen

---

# Architecture

- SwiftUI
- MVVM structure
- Models / ViewModels / Views separation
- MockCountryService for dummy data
- AppState as centralized in-memory store

Directory Structure (simplified):

- Models
- ViewModels
- Views
- Services
- AppState

---

# How to Run

1. Open `WorldTrackerIOS.xcodeproj`
2. Select an iPhone simulator
3. Build & Run (⌘R)

Requirements:
- Xcode 15+
- iOS 17+ (or project deployment target)

---

# Phase 2 – Data Architecture & Local Persistence

Planned improvements:

- Introduce SwiftData models
- Implement persistent visit storage
- Replace in-memory AppState storage with SwiftData-backed repository
- Ensure offline-first stability
- Prepare architecture for future networking

---

# Project Status

Phase 1 (UI Foundation with Dummy Data) is complete.
The application flow is fully implemented and stable.
