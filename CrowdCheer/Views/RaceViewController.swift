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
        
        //should only run this timer if user is a cheerer
        let nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "updateNearbyRunners", userInfo: nil, repeats: true)
    }
    
    func userTracker() {
       
        let runnerTracker = RunnerTracker()
        let cheererTracker = CheererTracker()
        
        //query current user's role
        //if runner, start runner tracker and if cheerer, start cheerer tracker
        let user = PFUser.currentUser()
        let role = (user.valueForKey("role"))!
        print("user role: ", role)
        
        if (role.isEqualToString("runner")) {
            runnerTracker.trackUserLocation()
            runnerTracker.saveUserPath()
            runnerTracker.saveUserLocation()
            updateLocsLabel.text = "Updating runner location..."
        }
        
        else if (role.isEqualToString("cheerer")) {
            cheererTracker.trackUserLocation()
            cheererTracker.saveUserPath()
            updateLocsLabel.text = "Updating cheerer location..."
//            let nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateNearbyRunners", userInfo: nil, repeats: true)
        }
        else {
            print("No valid role found.")
        }
    }
    
    
    func updateNearbyRunners() {
        
        let runnerMonitor = MonitorRunners()
        runnerMonitor.monitorCheerZone(){ (runnerLocations) -> Void in
            
            print("Runner List is ", runnerLocations!)
            var runnerUpdates: String = ""
//            for (runnerObj, runnerLoc) in runnerLocations! {
//                let runner = runnerObj
//                let loc = runnerLoc
//                let update = String(runner.username) + ": " + String(loc)
//                runnerUpdates.appendContentsOf(update)
//            }
            for runnerUpdate in runnerLocations! {
                let lat = runnerUpdate.latitude
                let lon = runnerUpdate.longitude
                let loc = String(lat) + " " + String(lon)
                runnerUpdates.appendContentsOf(loc)
            }
            print("Nearby runners label: ", runnerUpdates)
            self.updateCheerZoneLabel.text = runnerUpdates
        }
    }
}