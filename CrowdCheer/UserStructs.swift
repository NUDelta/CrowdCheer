//
//  users.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 10/28/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//
/*
import Foundation
struct runner: Tracking {
    var locationMgr: CLLocationManager!
    var timer: NSTimer
    var userPath: NSMutableArray
    
    
    
    func startLocationUpdates() {
        if locationMgr == nil {
            locationMgr = CLLocationManager()
        }
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1
        locationMgr.requestWhenInUseAuthorization()
        locationMgr.requestAlwaysAuthorization()
        locationMgr.startUpdatingLocation()
    }
    
    func trackUser(user: runner) {
        self.timer = NSTimer.scheduledTimerWithTimeInterval((1.0), target: self, selector: "eachSecond", userInfo: nil, repeats: true)
    }
    
    func eachSecond() {
        let thisUser: PFUser = PFUser.currentUser()
//        self.saveUserLoc(thisUser)
        self.userPath.addObject(self.locationManager.location!)
    }
    
//    func saveUserLoc(runner: PFUser) {
//        var loc: PFGeoPoint = PFGeoPoint.geoPointWithLocation(self.locations.lastObject)
//        var runnerLocation: PFObject = PFObject(className: "RunnerLocation")
//        runnerLocation.setObject(NSDate(), forKey: "time")
//        self.pace = MathController.stringifyAvgPaceFromDist(self.distance, overTime: self.seconds)
//        var runTime: Int = NSNumber.numberWithInt(self.seconds)
//        var distance: Int = NSNumber.numberWithFloat(self.distance)
//        runnerLocation.setObject(loc, forKey: "location")
//        runnerLocation.setObject(runner, forKey: "user")
//        runnerLocation.setObject(self.pace, forKey: "pace")
//        runnerLocation.setObject(distance, forKey: "distance")
//        runnerLocation.setObject(runTime, forKey: "runTime")
//        runnerLocation.saveInBackground()
//    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [Any]) {
        for newLocation: CLLocation in locations {
            if newLocation.horizontalAccuracy < 0 {
                return
            }
            else {
                if newLocation.horizontalAccuracy < 300 {
                    if self.locations.count > 0 {
                        self.distance += newLocation.distanceFromLocation(self.locations.lastObject)
                    }
                    self.locations.addObject(newLocation)
                }
            }
        }
    }
}

struct cheerer: Tracking {
    var locationManager: CLLocationManager
    var timer: NSTimer
    
    
    func startLocationUpdates() {
        if self.locationManager == nil {
            self.locationManager = CLLocationManager()
        }
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.activityType = CLActivityTypeFitness
        self.locationManager.distanceFilter = 1
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func trackUser(user: cheerer) {
        self.timer = NSTimer.scheduledTimerWithTimeInterval((1.0), target: self, selector: "eachSecond", userInfo: nil, repeats: true)
    }
    
    func eachSecond() {
        let thisUser: PFUser = PFUser.currentUser()
        self.saveUserLoc(thisUser)
    }
    
    func saveUserLoc(runner: PFUser) {
        var loc: PFGeoPoint = PFGeoPoint.geoPointWithLocation(self.locations.lastObject)
        var cheererLocation: PFObject = PFObject.objectWithClassName("CheererLocation")
        cheererLocation.setObject(NSDate(), forKey: "time")
        cheererLocation.setObject(loc, forKey: "location")
        cheererLocation.setObject(self.cheerer, forKey: "user")
        NSLog("CheererLocation is %@", loc)
        cheererLocation.saveInBackground()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        for newLocation: CLLocation in locations {
            if newLocation.horizontalAccuracy < 0 {
                return
            }
            else {
                if newLocation.horizontalAccuracy < 300 {
                    if self.locations.count > 0 {
                        self.distance += newLocation.distanceFromLocation(self.locations.lastObject)
                    }
                    self.locations.addObject(newLocation)
                }
            }
        }
    }
    
}
*/