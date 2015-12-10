//
//  RaceViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
/* Copyright © 2015 Delta Lab. All rights reserved.
locations = [CLLocation(latitude: 38.5, longitude: -120.2),
    CLLocation(latitude: 40.7000, longitude: -120.95000),
    CLLocation(latitude: 43.25200, longitude: -126.453000)]

*/

import UIKit
import Foundation
import CoreLocation
import MapKit
import Parse

class RaceViewController: UIViewController, CLLocationManagerDelegate {
    
    
    let isTracking: Bool = true
    let isRacer: Bool = false
    let isCheerer: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
         print("Object is doing a thing.")
        
        let runnerTracker = RunnerLocation()
        let cheererTracker = CheererLocation()
        runnerTracker.trackUserLocation()
        runnerTracker.saveUserLocation()
        cheererTracker.trackUserLocation()
        cheererTracker.saveUserLocation()
        
    }
}