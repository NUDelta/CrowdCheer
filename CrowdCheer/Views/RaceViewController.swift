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
    var runner: PFUser = PFUser()
    var userTrackerTimer: NSTimer = NSTimer()
    var nearbyRunnersTimer: NSTimer = NSTimer()
    
    @IBOutlet weak var updateLocsLabel: UILabel!
    @IBOutlet weak var updateRunner: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
        self.updateRunner.hidden = true
        self.userTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "userTracker", userInfo: nil, repeats: true)
        
    }
    
    func userTracker() {
       
        let runnerMonitor = RunnerMonitor()
        let cheererMonitor = CheererMonitor()
        
        //query current user's role
        //if runner, start runner tracker and if cheerer, start cheerer tracker
        let user = PFUser.currentUser()
        let role = (user.valueForKey("role"))!
        
        if (role.isEqualToString("runner")) {
            runnerMonitor.monitorUserLocation()
            runnerMonitor.updateUserPath()
            runnerMonitor.updateUserLocation()
            updateLocsLabel.text = "Updating runner location..."
        }
        
        else if (role.isEqualToString("cheerer")) {
            cheererMonitor.monitorUserLocation()
            cheererMonitor.updateUserPath()
            updateLocsLabel.text = "Updating cheerer location..."
            self.nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateNearbyRunners", userInfo: nil, repeats: true)
        }
        else {
            print("ERROR: No valid role found.")
        }
    }
    
    
    func updateNearbyRunners() {
        
        let nearbyRunners = NearbyRunners()
        nearbyRunners.checkCheerZone(){ (runnerLocations) -> Void in
            
            var update: String = ""
            for (runnerObj, runnerLoc) in runnerLocations! {
                self.runner = PFQuery.getUserObjectWithId(runnerObj.objectId!)
                let lat = runnerLoc.latitude
                let lon = runnerLoc.longitude
                let clLoc = CLLocation(latitude: lat, longitude: lon)
                let runnerName = (self.runner.valueForKey("name"))!
                let distance = (self.locationMgr.location?.distanceFromLocation(clLoc))!
                update = "Cheer for " + String(runnerName) + ": " + String(format: " %.02f", distance) + "m away"
            }
            
            //right now, we're automatically selecting the last runner on the list
            self.updateRunner.hidden = false
            self.updateRunner.setTitle(update, forState: UIControlState.Normal)
            
        }
    }
    
    @IBAction func cheerCommitment(sender: UIButton) {
        //call a function that will save a "cheer" object to parse
        
        let selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(self.runner)
        self.userTrackerTimer.invalidate()
        self.nearbyRunnersTimer.invalidate()
    }
}