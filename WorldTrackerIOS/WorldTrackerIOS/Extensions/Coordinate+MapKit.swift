//
//  Coordinate+MapKit.swift
//  WorldTrackerIOS
//
//  Created by seren on 4.03.2026.
//

import CoreLocation

extension Coordinate {
    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
}
