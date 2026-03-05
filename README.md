# World Tracker iOS

World Tracker is an iOS application that allows users to track the countries they have visited around the world.

Users can:
- mark countries as visited
- store visit dates and notes
- visualize visited countries on a world map
- track their travel statistics

The project was developed incrementally through multiple phases to focus on architecture, persistence, and feature development.

---

# Tech Stack

- Swift
- SwiftUI
- SwiftData
- MapKit
- MVVM Architecture
- Repository Pattern

---

# Architecture Overview

The project follows a **clean MVVM architecture** with a repository layer separating UI logic from persistence.

### View Layer
SwiftUI views:
- Countries list
- Country detail screen
- Map screen
- Stats screen

### State Management
`AppState` is responsible for:

- managing UI state
- coordinating data updates
- communicating with the repository layer

### Repository Layer

`VisitRepository` protocol abstracts the persistence layer.

Implementation:
- `SwiftDataVisitRepository`

This allows the app to switch persistence mechanisms in the future without changing UI code.

### Persistence

Visited country data is stored locally using **SwiftData**.

Stored fields include:

- countryId
- visited status
- visit date
- notes

---

# Development Phases

## Phase 1 — UI Foundation

Goal: build the full UI structure using mock data.

Implemented:
- Countries list
- Country detail screen
- visit toggle
- visit date picker
- notes editor
- basic tab navigation
- map and stats placeholders

---

## Phase 2 — Data Architecture & Persistence

Goal: introduce local persistence.

Implemented:
- SwiftData setup
- VisitEntity model
- VisitRepository protocol
- SwiftDataVisitRepository implementation
- AppState integration with repository
- data persistence across app launches

---

## Phase 3 — Map Integration

Goal: visualize visited countries geographically.

Implemented:
- MapKit integration
- visited countries rendered as map annotations
- annotation tap opens CountryDetailScreen
- map persistence using SwiftData data
- map QA validation

See `PHASE3_QA.md` for full test documentation.

---

# How to Run

Requirements:

- Xcode 15+
- iOS 17+
- macOS Sonoma or later

Steps:

1. Clone the repository
2. Open `WorldTrackerIOS.xcodeproj`
3. Select a simulator or connected device
4. Run the project

---

# Future Work (Phase 4)

Next development phase will introduce:

- Firebase Authentication
- Firestore cloud sync for visited countries
- async/await networking layer
- improved map UX
- expanded statistics dashboard

---

# License

This project is for educational and internship purposes.
