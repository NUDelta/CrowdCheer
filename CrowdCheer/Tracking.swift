//
//  Tracking.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 10/30/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import Parse


protocol Tracking: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    var distance: Float {get set}
    var pace: NSString {get set}
    var duration: Int32 {get}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func trackUserLocation()
    func saveUserPath()
    
}

//this tracking delegate would be like a start tracking all runners/cheerers
protocol TrackingDelegate {
    func startTracking()
    func stopTracking()
}


class RunnerTracker: NSObject, Tracking, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var distance: Float
    var pace: NSString
    let duration: Int32
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        self.distance = 0.0
        self.pace = ""
        self.duration = 0
        
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
    
    func trackUserLocation() {
        
        print(self.location.coordinate)
        let currentLoc:CLLocationCoordinate2D =  (self.location.coordinate)
        print("current location is: ", currentLoc)
        
        //testing monitoring code
        
        //end testing
    }
    
    func saveUserLocation() {
        let loc:CLLocationCoordinate2D =  self.location.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        pace = MathController.stringifyAvgPaceFromDist(distance, overTime: duration)
        
        let query = PFQuery(className: "CurrRunnerLocation")
        query.whereKey("user", equalTo: self.user)
        query.getFirstObjectInBackgroundWithBlock {
            (currLoc: PFObject?, error: NSError?) -> Void in
            if error != nil {
                print(error)
                //add runner
                let newCurrLoc = PFObject(className: "CurrRunnerLocation")
                newCurrLoc["location"] = geoPoint
                newCurrLoc["user"] = PFUser.currentUser()
                newCurrLoc["distance"] = self.distance
                newCurrLoc["pace"] = self.pace
//                newCurrLoc["duration"] = self.duration
                newCurrLoc["time"] = NSDate()
                newCurrLoc.saveInBackground()
                
            } else if let currLoc = currLoc {
                currLoc["location"] = geoPoint
                currLoc["user"] = PFUser.currentUser()
                currLoc["distance"] = self.distance
                currLoc["pace"] = self.pace
//                currLoc["duration"] = self.duration
                currLoc["time"] = NSDate()
                currLoc.saveInBackground()
            }
        }
    }
    func saveUserPath(){
        
        let loc:CLLocationCoordinate2D =  self.location.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        pace = MathController.stringifyAvgPaceFromDist(distance, overTime: duration)
        
        let object = PFObject(className:"RunnerLocations")
        print(geoPoint)
        print (user)
        print(self.distance)
        print(self.pace)
        print(NSDate())
        object["location"] = geoPoint
        object["user"] = PFUser.currentUser()
        object["distance"] = self.distance
        object["pace"] = self.pace
//        object["duration"] = self.duration
        object["time"] = NSDate()
        
        object.saveInBackgroundWithBlock { (_success:Bool, _error:NSError?) -> Void in
            if _error == nil
            {
                print("location saved")
            }
        }
    }
}

class CheererTracker: NSObject, Tracking, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var distance: Float
    var pace: NSString
    let duration: Int32
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        self.distance = 0.0
        self.pace = ""
        self.duration = 0
        
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
    
    func trackUserLocation() {
        
        print(self.location.coordinate)
        let currentLoc:CLLocationCoordinate2D =  (self.location.coordinate)
        print("current location is: ", currentLoc)
    }
    
    func saveUserPath(){
        
        let loc:CLLocationCoordinate2D =  self.location.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        pace = MathController.stringifyAvgPaceFromDist(distance, overTime: duration)
        
        let object = PFObject(className:"CheererLocations")
        object["location"] = geoPoint
        object["user"] = PFUser.currentUser()
        object["distance"] = distance
//        object["pace"] = pace
//        object["duration"] = duration
        object["time"] = NSDate()
        
        
        object.saveInBackgroundWithBlock { (_success:Bool, _error:NSError?) -> Void in
            if _error == nil
            {
                print("location saved")
            }
        }
    }
}
