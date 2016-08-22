//
//  Track.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 1/28/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import Parse


protocol Prime: Any {
    //get runner profile
    //get runner location
    
    var user: PFUser {get}
    var runner: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation! {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func getRunner() -> PFUser
    func getRunnerLocation(trackedRunner: PFUser, result:(runnerLoc: CLLocationCoordinate2D) -> Void)
    
}

class ContextPrimer: NSObject, Prime, CLLocationManagerDelegate {
    
    var user: PFUser
    var runner: PFUser
    var runnerObjID: String
    var locationMgr: CLLocationManager
    var location: CLLocation!
    let appDel = NSUserDefaults()
    
    //for Latency handling
    var currLoc = PFGeoPoint()
    var prevLocLat = 0.0
    var prevLocLon = 0.0
    var actualTime = NSDate()
    var setTime = NSDate()
    var getTime = NSDate()
    var speed = 0.0
    
    override init(){
        user = PFUser.currentUser()
        runner = PFUser()
        runnerObjID = "dummy"
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
        location = manager.location!
    }
    
    func getRunner() -> PFUser {
        
        let pairDict = appDel.dictionaryForKey(dictKey)
        runnerObjID = pairDict![PFUser.currentUser().objectId] as! String
        runner = PFQuery.getUserObjectWithId(runnerObjID)
        return runner
    }
    
    func resetRunner() {
        var cheerPair = [String: String]()
        cheerPair[PFUser.currentUser().objectId] = ""
        appDel.setObject(cheerPair, forKey: dictKey)
        appDel.synchronize()
    }
    
    func getRunnerLocation(trackedRunner: PFUser, result:(runnerLoc: CLLocationCoordinate2D) -> Void) {
        
        var runnerUpdate = CLLocationCoordinate2D()
        let now = NSDate()
        let seconds:NSTimeInterval = -30
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "CurrRunnerLocation")
        
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 30 seconds
        query.whereKey("user", equalTo: trackedRunner)
        query.orderByDescending("updatedAt")
        query.findObjectsInBackgroundWithBlock {
            (runnerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(runnerObjects!.count) updates.")
                if let runnerObjects = runnerObjects {
                    for object in runnerObjects {
                        self.currLoc = (object as! PFObject)["location"] as! PFGeoPoint
                        self.prevLocLat = (object as! PFObject)["prevLocLat"] as! Double
                        self.prevLocLon = (object as! PFObject)["prevLocLon"] as! Double
                        self.speed = (object as! PFObject)["speed"] as! Double
                        self.actualTime = (object as! PFObject)["time"] as! NSDate
                        self.setTime = object.updatedAt
                        self.getTime = NSDate()

                        runnerUpdate = CLLocationCoordinate2DMake(self.currLoc.latitude, self.currLoc.longitude)
                    }
                }
                
                result(runnerLoc: runnerUpdate)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \(error!.userInfo)")
                result(runnerLoc: runnerUpdate)
            }
        }
    }
    
    func handleLatency(runner: PFUser, actualTime: NSDate, setTime: NSDate, getTime: NSDate, showTime: NSDate) -> (delay: NSTimeInterval, calculatedRunnerLoc: CLLocationCoordinate2D) {
    
        let latency = PFObject(className:"Latency")
        
        let now = NSDate()
        let delay = now.timeIntervalSinceDate(actualTime)
        let previousLoc = CLLocationCoordinate2DMake(self.prevLocLat, self.prevLocLon)
        let currentLoc = CLLocationCoordinate2DMake(self.currLoc.latitude, self.currLoc.longitude)
        var calcRunnerLoc: CLLocationCoordinate2D = currentLoc
        
        let distTraveled = calculateDistTraveled(delay, speed: self.speed)
        let bearing = calculateBearing(previousLoc, coorB: currentLoc)
        calcRunnerLoc = calculateLocation(currentLoc, bearing: bearing, distance: distTraveled)
        
        
        latency["spectator"] = self.user
        latency["runner"] = runner
        latency["actualTime"] = actualTime
        latency["setTime"] = setTime
        latency["getTime"] = getTime
        latency["showTime"] = now
        latency["totalDelay"] = delay
        
        latency.save()
        
        return (delay, calcRunnerLoc)
    }
    
    func calculateDistTraveled(delay: NSTimeInterval, speed: Double) -> Double {
        
        //calculate additional distance based on second delay + pace
        let distTraveled = speed*delay
        print("calculated distance traveled: \(distTraveled)")
        return distTraveled
    }
    
    func calculateBearing(coorA: CLLocationCoordinate2D, coorB: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: coorA.latitude, longitude: coorA.longitude)
        let locB = CLLocation(latitude: coorB.latitude, longitude: coorB.longitude)
        
        let bearing = bearingDegrees(locA, locB: locB)
        return bearing
    }
    
    func calculateLocation(runnerLoc: CLLocationCoordinate2D, bearing: Double, distance: Double) -> CLLocationCoordinate2D {
        //generate new loc point based on original loc + distance + bearing
        
        var calcRunnerLoc = runnerLoc
        let earthRadius = 6372797.6
        
        let lat1 = DegreesToRadians(runnerLoc.latitude)
        let lon1 = DegreesToRadians(runnerLoc.longitude)
        
        var lat2 = asin(sin(lat1)*cos(distance/earthRadius) + cos(lat1)*sin(distance/earthRadius)*cos(bearing))
        var lon2 = lon1 + atan2(sin(bearing)*sin(distance/earthRadius)*cos(lat1), cos(distance/earthRadius) - sin(lat1)*sin(lat2))
        
        lat2 = RadiansToDegrees(lat2)
        lon2 = RadiansToDegrees(lon2)
        
        calcRunnerLoc = CLLocationCoordinate2DMake(lat2, lon2)
        
        return calcRunnerLoc
    }
    
    func DegreesToRadians(degrees: Double ) -> Double {
        return degrees * M_PI / 180
    }
    
    func RadiansToDegrees(radians: Double) -> Double {
        return radians * 180 / M_PI
    }
    
    
    func bearingRadian(locA: CLLocation, locB:CLLocation) -> Double {
        
        let lat1 = DegreesToRadians(locA.coordinate.latitude)
        let lon1 = DegreesToRadians(locA.coordinate.longitude)
        
        let lat2 = DegreesToRadians(locB.coordinate.latitude);
        let lon2 = DegreesToRadians(locB.coordinate.longitude);
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    func bearingDegrees(locA: CLLocation, locB:CLLocation) -> Double{
        return   RadiansToDegrees(bearingRadian(locA, locB: locB))
    }
}