# World Tracker iOS

World Tracker is an iOS application that allows users to track the countries they have visited around the world.

Users can:

* mark countries as visited
* store visit dates and notes
* visualize visited countries on a world map
* track their travel statistics

The project was developed incrementally through multiple phases, focusing on architecture, persistence, and feature evolution.

---

# Tech Stack

* Swift
* SwiftUI
* SwiftData
* MapKit
* Firebase Authentication
* Cloud Firestore
* MVVM Architecture
* Repository Pattern

---

# Architecture Overview

The project follows a **clean MVVM architecture** with a repository layer that separates UI logic from persistence.

## View Layer

SwiftUI views:

* Countries list
* Country detail screen
* Map screen
* Stats screen

## State Management

`AppState` is responsible for:

* managing UI state
* coordinating data updates
* communicating with the repository layer

## Repository Layer

`VisitRepository` protocol abstracts the persistence layer.

Current implementation:

* `SwiftDataVisitRepository`

This abstraction allows switching persistence mechanisms without affecting UI code.

## Persistence

Visited country data is stored locally using **SwiftData** and can be synced to **Cloud Firestore** for authenticated users.

Stored fields:

* `countryId`
* `isVisited`
* `visitedDate`
* `notes`
* `updatedAt`

---

# Development Phases

## Phase 1 — UI Foundation

**Goal:** Build the full UI structure using mock data.

**Implemented:**

* Countries list
* Country detail screen
* Visit toggle
* Visit date picker
* Notes editor
* Basic tab navigation
* Map and stats placeholders

---

## Phase 2 — Data Architecture & Persistence

**Goal:** Introduce local persistence.

**Implemented:**

* SwiftData setup
* `VisitEntity` model
* `VisitRepository` protocol
* `SwiftDataVisitRepository` implementation
* `AppState` integration with repository
* Data persistence across app launches

---

## Phase 3 — Map Integration

**Goal:** Visualize visited countries geographically.

**Implemented:**

* MapKit integration
* Visited countries rendered as map annotations
* Annotation tap opens Country Detail screen
* Map persistence using SwiftData data
* QA validation

📄 See `docs/PHASE3_QA.md` for full test documentation.

---

## Phase 4 — Stats + Cloud Sync + Reliability

**Goal:** Add authenticated cloud syncing, travel statistics, and improve reliability.

**Implemented:**

* Firebase Authentication integration
* Firestore sync for visited countries
* Sync-aware repository and state flow
* Persisted user session handling
* Expanded statistics dashboard
* Improved reliability for relaunch and restore flows
* Offline-aware data handling and resync support
* Full QA validation

### Firebase Setup

To enable cloud sync locally:

* Configure Firebase for the iOS target
* Add `GoogleService-Info.plist` to the Xcode project

### Sync Behavior

* Visit data is stored per authenticated user
* Changes to visits, notes, and dates sync to Firestore
* Local data remains available on device
* Offline edits are preserved and synced on reconnect
* Firestore schema is defined in `docs/FIRESTORE_SCHEMA.md`

📄 See `docs/PHASE4_QA.md` for full Phase 4 test coverage.

---

# How to Run

## Requirements

* Xcode 15+
* iOS 17+
* macOS Sonoma or later

## Steps

1. Clone the repository
2. Open `WorldTrackerIOS.xcodeproj`
3. Select a simulator or connected device
4. Run the project

---

# License

This project is developed for educational and internship purposes.
