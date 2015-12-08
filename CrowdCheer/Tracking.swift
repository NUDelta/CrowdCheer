//
//  Runner.swift
//  CrowdCheer
//
//  Created by Christina Kim on 10/30/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation

@objc
protocol Tracking {
    var locations: Array<CLLocation> {get set}
    var distance: NSNumber {get set}
    optional var pace: NSTimeInterval {get set}
    var duration: NSTimeInterval {get}
}

//this tracking delegate would be like a start tracking all runners/cheerers
protocol TrackingDelegate {
    func startTracking()
    func stopTracking()
}
