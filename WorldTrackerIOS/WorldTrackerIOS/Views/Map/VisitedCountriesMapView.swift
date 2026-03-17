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
        
        // Ensure proper rendering
        mapView.isOpaque = true

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

        // Load overlays asynchronously to prevent main thread blocking
        let coordinator = context.coordinator
        DispatchQueue.global(qos: .userInitiated).async { [weak coordinator] in
            let overlaysByCountry = CountryBoundaryService.shared.getCountryOverlays()
            
            // Update map on main thread
            DispatchQueue.main.async { [weak coordinator] in
                guard let coordinator = coordinator else { return }
                coordinator.overlaysByCountry = overlaysByCountry
                let allOverlays = overlaysByCountry.values.flatMap { $0 }
                mapView.addOverlays(allOverlays)
            }
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the coordinator's visited countries set
        context.coordinator.visitedCountryIDs = visitedCountryIDs
        
        // Only update if we have overlays loaded
        guard !mapView.overlays.isEmpty, 
              !context.coordinator.overlaysByCountry.isEmpty else { 
            return 
        }
        
        // Update renderers only if needed (throttled by coordinator)
        context.coordinator.updateRenderersIfNeeded(for: mapView)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var visitedCountryIDs: Set<String> {
            didSet {
                // Track if visited countries actually changed
                if oldValue != visitedCountryIDs {
                    needsRendererUpdate = true
                }
            }
        }
        var overlaysByCountry: [String: [MKOverlay]] = [:]
        
        // Cache overlay -> countryID lookups for performance
        private var overlayCountryCache: [ObjectIdentifier: String] = [:]
        private var needsRendererUpdate = false

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
            let overlayID = ObjectIdentifier(overlay)
            
            // Check cache first
            if let cached = overlayCountryCache[overlayID] {
                return cached
            }
            
            // Find and cache
            for (countryID, overlays) in overlaysByCountry {
                if overlays.contains(where: { $0 === overlay }) {
                    overlayCountryCache[overlayID] = countryID
                    return countryID
                }
            }
            return nil
        }
        
        func updateRenderersIfNeeded(for mapView: MKMapView) {
            guard needsRendererUpdate else { return }
            needsRendererUpdate = false
            
            // Refresh renderers
            for overlay in mapView.overlays {
                if let renderer = mapView.renderer(for: overlay) as? MKOverlayPathRenderer {
                    configure(renderer: renderer, for: overlay)
                    renderer.setNeedsDisplay()
                }
            }
        }
    }
}
