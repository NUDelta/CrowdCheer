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
    
    //for Latency logging
    var actualTime = NSDate()
    var setTime = NSDate()
    var getTime = NSDate()
    
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
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
                        
                        self.actualTime = (object as! PFObject)["time"] as! NSDate
                        self.setTime = object.updatedAt
                        self.getTime = NSDate()
                        
                        print("location: ", location)
                        runnerUpdate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
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
    
    func logLatency(runner: PFUser, actualTime: NSDate, setTime: NSDate, getTime: NSDate, showTime: NSDate) {
        
        let latency = PFObject(className:"Latency")
        latency["spectator"] = self.user
        latency["runner"] = runner
        latency["actualTime"] = actualTime
        latency["setTime"] = setTime
        latency["getTime"] = getTime
        latency["showTime"] = showTime
        
        latency.save()
    }
}