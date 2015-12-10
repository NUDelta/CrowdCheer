//
//  Tracking.swift
//  CrowdCheer
//
//  Created by Christina Kim on 10/30/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import Parse


protocol Tracking: Any {
//    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var locations: Array<CLLocation> {get set}
    var distance: Float {get set}
    var pace: NSString {get set}
    var duration: Int32 {get}
    
    func trackUserLocation(locMgr: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func saveUserLocation(locMgr: CLLocationManager, didUpdateLocations locations: [CLLocation])
}

//this tracking delegate would be like a start tracking all runners/cheerers
protocol TrackingDelegate {
    func startTracking()
    func stopTracking()
}


class RunnerLocation: NSObject, Tracking, CLLocationManagerDelegate {
    
//    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager = CLLocationManager()
    var locations: Array<CLLocation> = []
    var distance: Float = 0.0
    var pace: NSString = ""
    let duration: Int32 = 0
    
    func trackUserLocation(locMgr: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print(locationMgr.location?.coordinate)
        print(locMgr.location?.coordinate)
        let currentLoc:CLLocationCoordinate2D =  (locMgr.location?.coordinate)!
        print("current location is:" ,currentLoc)
    }
    
    func saveUserLocation(locMgr: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        let loc:CLLocationCoordinate2D =  locMgr.location!.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        pace = MathController.stringifyAvgPaceFromDist(distance, overTime: duration)
        
        let object = PFObject(className:"RunnerLocations")
        object["location"] = geoPoint
        object["user"] = PFUser.currentUser()
        object["distance"] = distance
        object["pace"] = pace
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

class CheererLocation: NSObject, Tracking, CLLocationManagerDelegate {
    
//    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager = CLLocationManager()
    var locations: Array<CLLocation> = []
    var distance: Float = 0.0
    var pace: NSString = ""
    let duration: Int32 = 0
    
    func trackUserLocation(locMgr: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let currentLoc =  locationMgr.location!.coordinate
        print("current location is: %@", currentLoc)
    }
    
    func saveUserLocation(locMgr: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        let loc =  locationMgr.location!.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        pace = MathController.stringifyAvgPaceFromDist(distance, overTime: duration)
        
        let object = PFObject(className:"RunnerLocations")
        object["location"] = geoPoint
        object["user"] = PFUser.currentUser()
        object["distance"] = distance
        object["pace"] = pace
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
