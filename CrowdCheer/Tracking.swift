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
//    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    var distance: Float {get set}
    var pace: NSString {get set}
    var duration: Int32 {get}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func trackUserLocation()
    func saveUserLocation()
    
}

//this tracking delegate would be like a start tracking all runners/cheerers
protocol TrackingDelegate {
    func startTracking()
    func stopTracking()
}


class RunnerTracker: NSObject, Tracking, CLLocationManagerDelegate {
    
//    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var distance: Float
    var pace: NSString
    let duration: Int32
    
    override init(){
//        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = CLLocation(latitude: 0, longitude: 0)
        self.distance = 0.0
        self.pace = ""
        self.duration = 0
        
        //initialize location manager
        super.init()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
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
    
    func saveUserLocation(){
        
        let loc:CLLocationCoordinate2D =  self.location.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        pace = MathController.stringifyAvgPaceFromDist(distance, overTime: duration)
        
        let object = PFObject(className:"RunnerLocations")
        print(geoPoint)
//        print (user)
        print(self.distance)
        print(self.pace)
        print(NSDate())
        object["location"] = geoPoint
//        object["user"] = PFUser.currentUser()
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
    
    //    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var distance: Float
    var pace: NSString
    let duration: Int32
    
    override init(){
        //        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = CLLocation(latitude: 0, longitude: 0)
        self.distance = 0.0
        self.pace = ""
        self.duration = 0
        
        //initialize location manager
        super.init()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
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
    
    func saveUserLocation(){
        
        let loc:CLLocationCoordinate2D =  self.location.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        pace = MathController.stringifyAvgPaceFromDist(distance, overTime: duration)
        
        let object = PFObject(className:"CheererLocations")
        object["location"] = geoPoint
//        object["user"] = PFUser.currentUser()
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
