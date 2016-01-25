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
    
    @IBOutlet weak var updateLocsLabel: UILabel!
    @IBOutlet weak var updateCheerZoneLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
        let userTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "userTracker", userInfo: nil, repeats: true)
        let nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "updateNearbyRunners", userInfo: nil, repeats: true)
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
            runnerTracker.saveUserPath()
            runnerTracker.saveUserLocation()
            updateLocsLabel.text = "Updating your location..."
        }
        else if ((role?.isEqualToString("cheerer")) != nil) {
            cheererTracker.trackUserLocation()
            cheererTracker.saveUserPath()
            runnerTracker.saveUserLocation()
            updateLocsLabel.text = "Updating your location..."
        }
        else {
            print("No valid role found.")
        }
    }
    
    
    func updateNearbyRunners() {
        
        let runnerMonitor = MonitorRunners()
        runnerMonitor.monitorCheerZone(){ (runnerLocations) -> Void in
            print("Runner List is ", runnerLocations)
            var locList: String = ""
            for runner in runnerLocations! {
                let lat = runner.latitude
                let lon = runner.longitude
                let loc = String(lat) + " " + String(lon)
                locList.appendContentsOf(loc)
            }
            print("Nearby runners label: ", locList)
            self.updateCheerZoneLabel.text = locList
        }
    }
}