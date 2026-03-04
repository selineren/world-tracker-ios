//
//  MapScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 25.02.2026.
//

import SwiftUI
import MapKit

struct MapScreen: View {
    @EnvironmentObject private var appState: AppState
    private let countries = MockCountryService().loadCountries()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
        )
    )

    var visitedCountries: [Country] {
        countries.filter { appState.visitedCountryIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(visitedCountries) { country in
                    Annotation(country.name, coordinate: country.centroid.clLocation) {
                        VStack(spacing: 2) {
                            Text(country.flagEmoji)
                            Image(systemName: "mappin.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
