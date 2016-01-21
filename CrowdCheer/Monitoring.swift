//
//  Monitoring.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import Parse


protocol Monitoring: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    var runnersNearby: Set<PFUser> {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion)
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion)
    func monitorCheerZone() //create a geofence and print out current runners in my zone every 5 seconds
    
}

class MonitorRunners: NSObject, Monitoring, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var runnersNearby: Set<PFUser>
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        self.runnersNearby = []
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.Fitness
        self.locationMgr.distanceFilter = 1;
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = manager.location!
        print("locations = \(location.coordinate.latitude) \(location.coordinate.longitude)")
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entering region")
    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exiting region")
    }
    
    func monitorCheerZone() {
        //set up a geofence around me
        //query runners' locations from parse
        //check if runners are in my geofence
        //if they are, print them out
        
        let cheerZone = CLCircularRegion(center: location.coordinate, radius: 500, identifier: "cheerZone")
        locationMgr.startMonitoringForRegion(cheerZone)
        
        
        
//        if cheerZone.containsCoordinate(coordinate: CLLocationCoordinate2D)
        
    }
    
}

class MonitorMyRunner: NSObject, Monitoring, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var runnersNearby: Set<PFUser>
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        self.runnersNearby = []
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.Fitness
        self.locationMgr.distanceFilter = 1;
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = manager.location!
        print("locations = \(location.coordinate.latitude) \(location.coordinate.longitude)")
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entering region")
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exiting region")
    }
    
    func monitorCheerZone() {
        //set up a geofence around me
        //query parse for my runner's location
        //check if my runner is in my geofence
        //if they are, print them out
    }
}

