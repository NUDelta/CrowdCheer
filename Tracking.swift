//
//  runner.swift
//  CrowdCheer
//
//  Created by Christina Kim on 10/30/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation

public protocol Tracking {
    func startLocationUpdates()
    func trackUser()
    func locationManager()
//    struct position
}

//this tracking delegate would be like a start tracking all runners/cheerers
protocol TrackingDelegate {
    func startTracking()
    func stopTracking()
}
