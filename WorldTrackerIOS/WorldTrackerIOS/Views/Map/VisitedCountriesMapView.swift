//
//  VisitedCountriesMapView.swift
//  WorldTrackerIOS
//
//  Created by seren on 15.03.2026.
//

import SwiftUI
import MapKit

struct VisitedCountriesMapView: UIViewRepresentable {
    let visitedCountryIDs: Set<String>

    func makeCoordinator() -> Coordinator {
        Coordinator(visitedCountryIDs: visitedCountryIDs)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator

        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
            mapView.preferredConfiguration = config
        }

        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = false

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
        )
        mapView.setRegion(region, animated: false)

        let overlaysByCountry = CountryBoundaryService.shared.loadCountryOverlays()
        context.coordinator.overlaysByCountry = overlaysByCountry

        let allOverlays = overlaysByCountry.values.flatMap { $0 }
        mapView.addOverlays(allOverlays)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the coordinator's visited countries set
        context.coordinator.visitedCountryIDs = visitedCountryIDs
        
        // Force refresh all overlays to pick up new colors
        for overlay in mapView.overlays {
            if let renderer = mapView.renderer(for: overlay) as? MKOverlayPathRenderer {
                context.coordinator.configure(renderer: renderer, for: overlay)
                renderer.setNeedsDisplay()
            }
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var visitedCountryIDs: Set<String>
        var overlaysByCountry: [String: [MKOverlay]] = [:]

        init(visitedCountryIDs: Set<String>) {
            self.visitedCountryIDs = visitedCountryIDs
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                configure(renderer: renderer, for: overlay)
                return renderer
            }

            if let multiPolygon = overlay as? MKMultiPolygon {
                let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
                configure(renderer: renderer, for: overlay)
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func configure(renderer: MKOverlayPathRenderer, for overlay: MKOverlay) {
            let countryID = countryID(for: overlay)

            if let countryID, visitedCountryIDs.contains(countryID) {
                // Visited countries - vibrant green
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.7)
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.9)
                renderer.lineWidth = 1.5
            } else {
                // Unvisited countries - neutral gray
                renderer.fillColor = UIColor.systemGray5.withAlphaComponent(0.85)
                renderer.strokeColor = UIColor.systemGray3.withAlphaComponent(0.7)
                renderer.lineWidth = 0.5
            }
        }

        private func countryID(for overlay: MKOverlay) -> String? {
            for (countryID, overlays) in overlaysByCountry {
                if overlays.contains(where: { $0 === overlay }) {
                    return countryID
                }
            }
            return nil
        }
    }
}
