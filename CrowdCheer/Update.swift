//
//  Update.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 1/28/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import Parse

protocol Update: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func updateStatus()
}

class updateRunner: NSObject, Update, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.Fitness
        self.locationMgr.distanceFilter = 1;
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func updateStatus() {
        //mark runner as cheered
        //update runner pace
        //update runner vitals
        
    }
}

class updateCheerer: NSObject, Update, CLLocationManagerDelegate {

    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.Fitness
        self.locationMgr.distanceFilter = 1;
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func updateStatus() {
        //update cheerer availability
        
    }
}