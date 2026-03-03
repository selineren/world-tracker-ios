# WorldTracker iOS

WorldTracker is an iOS application built with SwiftUI following a clean MVVM architecture.

The goal of the project is to track visited countries, manage visit dates and notes, and progressively expand into map visualization and networking.

---

## 🏗 Architecture Overview

The project follows a layered architecture:

UI (SwiftUI Views)
    ↓
AppState (ObservableObject – UI state & actions)
    ↓
VisitRepository (protocol abstraction)
    ↓
SwiftDataVisitRepository (SwiftData implementation)
    ↓
SwiftData (VisitEntity local persistence)

### Key Principles

- Separation of concerns
- Repository pattern for data abstraction
- Local-first persistence (SwiftData)
- SwiftUI reactive state management
- Clean phase-based development

---

## 📦 Phase 1 – UI Foundation (Dummy Data)

Goal: Establish complete UI structure and navigation using mock data.

Included:
- MVVM project structure
- Country list UI
- Country detail screen
- Visited toggle
- Visit date selection
- Notes editor
- Tab navigation
- Map placeholder
- Stats placeholder
- UI polish & empty states

Result:
✔ Full app flow implemented  
✔ Clean UI architecture  
✔ Ready for persistence integration  

---

## 💾 Phase 2 – Data Architecture & Local Persistence

Goal: Ensure stable local data handling before networking.

Implemented:
- SwiftData model container setup
- `VisitEntity` persistence model
- Repository pattern abstraction
- `SwiftDataVisitRepository` implementation
- AppState integration with repository
- Persistent visited state
- Persistent visit date
- Persistent notes
- QA validation & edge case handling

Result:
✔ Data persists across relaunch  
✔ No duplicate entities  
✔ Clean separation between UI and persistence  
✔ Architecture ready for expansion  

---

## 🧪 Testing

Persistence behavior validated in:
- `PHASE2_QA.md`

Tested:
- Toggle visited ON/OFF
- Custom visit date
- Notes persistence
- Duplicate protection
- Stats accuracy
- Relaunch stability

---

## 🚀 Next Phases

### Phase 3 – Map Visualization
- Integrate MapKit
- Highlight visited countries
- Sync map state with persistence layer

### Phase 4 – Networking
- Add remote data source
- Sync local and remote persistence
- Introduce authentication (if required)

---

## 📱 Minimum Requirements

- iOS 17+
- SwiftData
- SwiftUI

---

## 👩‍💻 Author

Built as part of an iOS internship project focused on clean architecture and progressive feature development.
