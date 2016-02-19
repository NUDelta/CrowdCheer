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
    var userMonitorTimer: NSTimer = NSTimer()
    var nearbyRunnersTimer: NSTimer = NSTimer()
    var runnerMonitor: RunnerMonitor = RunnerMonitor()
    var cheererMonitor: CheererMonitor = CheererMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    @IBOutlet weak var updateLocsLabel: UILabel!
    @IBOutlet weak var updateRunner: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
        self.updateRunner.hidden = true
        self.runnerMonitor = RunnerMonitor()
        self.cheererMonitor = CheererMonitor()
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "monitorUser", userInfo: nil, repeats: true)
        self.nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateNearbyRunners", userInfo: nil, repeats: true)
        
    }
    
    func monitorUser() {
        
        //query current user's role
        //if runner, start runner tracker and if cheerer, start cheerer tracker
        let user = PFUser.currentUser()
        let role = (user.valueForKey("role"))!
        
        if (role.isEqualToString("runner")) {
            self.runnerMonitor.monitorUserLocation()
            self.runnerMonitor.updateUserPath()
            self.runnerMonitor.updateUserLocation()
            updateLocsLabel.text = "Tracking your run..."
            self.updateRunner.hidden = true
            self.nearbyRunnersTimer.invalidate()
        }
        
        else if (role.isEqualToString("cheerer")) {
            self.cheererMonitor.monitorUserLocation()
            self.cheererMonitor.updateUserPath()
            updateLocsLabel.text = "Searching for runners..."
            
            
        }
        else {
            print("ERROR: No valid role found.")
        }
    }
    
    
    func updateNearbyRunners() {
        
        self.nearbyRunners = NearbyRunners()
        self.nearbyRunners.checkCheerZone(){ (runnerLocations) -> Void in
            
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
            self.updateRunner.setTitle(update, forState: UIControlState.Normal)
            self.updateRunner.hidden = false
            
        }
    }
    
    @IBAction func cheerCommitment(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:cheerer pairing
        
        self.selectedRunners = SelectedRunners()
        self.selectedRunners.selectRunner(self.runner)
        self.userMonitorTimer.invalidate()
        self.nearbyRunnersTimer.invalidate()
    }
}