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
    func trackUser(delegate: Self)
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [Any])
//    func saveUserLocation()
    func eachSecond()
//    struct position
    
    var locationMgr: CLLocationManager {get set}
    var timer: NSTimer {get set}
    var userPath: NSMutableArray {get set}
}

//this tracking delegate would be like a start tracking all runners/cheerers
protocol TrackingDelegate {
    func startTracking()
    func stopTracking()
}
