//
//  CountryDetailScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 26.02.2026.
//

import SwiftUI

struct CountryDetailScreen: View {
    @EnvironmentObject private var appState: AppState
    let country: Country

    // MARK: - Clean bindings

    private var isVisited: Binding<Bool> {
        Binding(
            get: { appState.visit(for: country.id).isVisited },
            set: { newValue in
                if newValue {
                    // turning ON: keep existing date if present, otherwise default to today
                    let existing = appState.visit(for: country.id).visitedDate
                    appState.setVisited(country.id, isVisited: true, visitedDate: existing ?? Date())
                } else {
                    appState.setVisited(country.id, isVisited: false)
                }
            }
        )
    }

    private var visitDate: Binding<Date> {
        Binding(
            get: { appState.visit(for: country.id).visitedDate ?? Date() },
            set: { newDate in
                appState.setVisited(country.id, isVisited: true, visitedDate: newDate)
            }
        )
    }

    private var notes: Binding<String> {
        Binding(
            get: { appState.visit(for: country.id).notes },
            set: { appState.updateNotes(country.id, notes: $0) }
        )
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Text(country.flagEmoji)
                        .font(.system(size: 44))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(country.name)
                            .font(.title2).bold()
                        Text(country.continent.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Visit") {
                Toggle("Visited", isOn: isVisited)

                if isVisited.wrappedValue {
                    DatePicker(
                        "Visit date",
                        selection: visitDate,
                        displayedComponents: [.date]
                    )
                }
            }

            Section("Notes") {
                TextEditor(text: notes)
                    .frame(minHeight: 120)
            }

            Section("Collection (Phase 1)") {
                Text("Coming soon: photos / stamps / souvenirs")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
