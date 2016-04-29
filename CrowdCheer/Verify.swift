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
    func recordCheererAudio()
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

class verifiedDelivery: NSObject, Deliver, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func recordCheererAudio() {
        
    }
}

class verifiedReceival: NSObject, Receive, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func recordRunnerAudio() {
        
    }
}

class verifiedReaction: NSObject, React, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func trackPerformanceChange() {
        
    }
}


