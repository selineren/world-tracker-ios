# World Tracker iOS

A SwiftUI-based iOS application for tracking countries you've visited and those you want to visit, with interactive map visualization, personal notes, and cloud synchronization.

## Overview

World Tracker helps users document their travel experiences by:
- Marking countries as visited or on their wishlist
- Adding photos and notes for each country
- Visualizing their travel progress on an interactive map
- Earning achievements as they explore more of the world
- Syncing data across devices with Firebase

## Features

### Core Functionality
- **Country Tracking** – Mark countries as visited or want-to-visit
- **Interactive Map** – Visual representation of tracked countries using MapKit with optimized rendering
- **Photo & Notes** – Add personal memories and observations for each country
- **Search & Filter** – Find countries by name or filter by continent

### Progress & Insights
- **Stats Dashboard** – Track visited countries, continents, and world coverage percentage
- **Achievements System** – Unlock milestones based on travel progress

### Sync & Reliability
- **Firebase Authentication** – Secure user accounts with email/password
- **Cloud Sync** – Automatic synchronization with Firestore
- **Offline Support** – Full functionality without internet, with automatic sync recovery

## Tech Stack

**Frontend**
- SwiftUI
- MapKit

**Data & Persistence**
- SwiftData (local storage)
- Firestore (cloud storage)
- Firebase Authentication

**Patterns & Architecture**
- MVVM (Model-View-ViewModel)
- Repository Pattern (abstraction over local/cloud storage)

## Architecture

The app follows a clean, layered architecture:
- SwiftUI Views    
- ViewModels (AppState) 
- Repository Layer (Local + Cloud)
- SwiftData ←→ Sync ←→ Firestore 

**Key Components:**
- **AppState**: Central state management coordinating repositories and sync
- **Repository Pattern**: Unified interface for local (SwiftData) and cloud (Firestore) data sources
- **SyncService**: Handles bi-directional synchronization between local and cloud storage
- **AuthService**: Manages Firebase authentication state

## Development Phases

The project was built iteratively across multiple phases:

1. **Foundation** – Core SwiftUI setup, country data model, basic list view
2. **Map Integration** – MapKit visualization with country boundaries and visit state rendering
3. **Data Enrichment** – Added photos, notes, and want-to-visit functionality
4. **Gamification** – Stats dashboard and achievements system
5. **Search & Discovery** – Country search and continent-based filtering
6. **Cloud Sync** – Firebase integration with authentication and Firestore synchronization
7. **Optimization** – Map rendering performance improvements and offline support

## How to Run

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Active internet connection (for Firebase features)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/world-tracker-ios.git
   cd world-tracker-ios

2. Configure Firebase
   • Create a Firebase project at firebase.google.com
   • Add an iOS app to your Firebase project
   • Download Google​Service​-​Info​.plist and add it to the Xcode project
   • Enable Authentication (Email/Password) and Firestore Database in Firebase Console

3. Open in Xcode
open WorldTrackerIOS.xcodeproj

4. Run the app
   • Select a simulator or connected device
   • Press Cmd + ​R to build and run

Notes

Firebase Configuration
The app requires a valid Google​Service​-​Info​.plist file for Firebase features to work. Without it, the app will fail to launch. If you want to run the app without Firebase, you'll need to modify the initialization code in WorldTrackerIOSApp.swift􀰓.

Offline Mode
The app fully supports offline usage. All changes made offline are queued and automatically synchronized when connectivity is restored.

Country Data
Country boundaries and geographic data are loaded from embedded GeoJSON files in the app bundle.

Built with SwiftUI • Designed for iOS 17+
