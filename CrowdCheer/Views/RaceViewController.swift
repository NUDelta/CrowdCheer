//
//  RaceViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
// Copyright © 2015 Delta Lab. All rights reserved.


import UIKit
import Foundation
import CoreLocation
import MapKit
import Parse

class RaceViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationMgr: CLLocationManager = CLLocationManager()
    let isTracking: Bool = true
    let isRunner: Bool = false
    let isCheerer: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "userTracker", userInfo: nil, repeats: true)
    }
    
    func userTracker() {
       
        let runnerTracker = RunnerTracker()
        let cheererTracker = CheererTracker()
        
        //query current user's role
        //if runner, start runner tracker and if cheerer, start cheerer tracker
        let user = PFUser.currentUser()
        let role = user.valueForKey("role")
        
        if ((role?.isEqualToString("runner")) != nil) {
            runnerTracker.trackUserLocation()
            runnerTracker.saveUserLocation()
        }
        else if ((role?.isEqualToString("cheerer")) != nil) {
            cheererTracker.trackUserLocation()
            cheererTracker.saveUserLocation()
        }
        else {
            print("No valid role found.")
        }
    }
}