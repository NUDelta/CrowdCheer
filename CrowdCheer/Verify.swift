//
//  Verify.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 1/28/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import Parse


protocol Deliver: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func spectatorDidCheer(runner: PFUser, didCheer: Bool)
    func recordSpectatorAudio()
}

protocol Receive: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func recordRunnerAudio()
}

protocol React: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func trackPerformanceChange()
}

class VerifiedDelivery: NSObject, Deliver, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.currentUser()!
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            locationMgr.allowsBackgroundLocationUpdates = true
        }
        locationMgr.pausesLocationUpdatesAutomatically = true
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func spectatorDidCheer(runner: PFUser, didCheer: Bool) {
        
        //query Cheer object using spectatorID, runnerID, maybe time?
        //update object with field didCheer & corresponding value
        
//        let now = NSDate()
//        let seconds:NSTimeInterval = -1200
//        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "Cheers")
        
        query.whereKey("runner", equalTo: runner)
        query.whereKey("spectator", equalTo: user)
//        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
        query.getFirstObjectInBackgroundWithBlock {
            (cheer: PFObject?, error: NSError?) -> Void in
            if error != nil {
                print(error)
            } else if let cheer = cheer {
                cheer["didCheer"] = didCheer
                cheer.saveInBackground()
            }
        }
    }
    
    func recordSpectatorAudio() {
        
    }
}

class VerifiedReceival: NSObject, Receive, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.currentUser()!
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            locationMgr.allowsBackgroundLocationUpdates = true
        }
        locationMgr.pausesLocationUpdatesAutomatically = true
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func recordRunnerAudio() {
        
    }
}

class VerifiedReaction: NSObject, React, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.currentUser()!
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            locationMgr.allowsBackgroundLocationUpdates = true
        }
        locationMgr.pausesLocationUpdatesAutomatically = true
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func trackPerformanceChange() {
        
    }
}


