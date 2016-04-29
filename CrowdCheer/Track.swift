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
    
    override init(){
        self.user = PFUser.currentUser()
        self.runner = PFUser()
        self.runnerObjID = "dummy"
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
        self.location = manager.location!
    }
    
    func getRunner() -> PFUser {
        
        let pairDict = self.appDel.dictionaryForKey(dictKey)
        runnerObjID = pairDict![PFUser.currentUser().objectId] as! String
        runner = PFQuery.getUserObjectWithId(runnerObjID)
        return runner
    }
    
    func resetRunner() {
        var cheerPair = [String: String]()
        cheerPair[PFUser.currentUser().objectId] = ""
        self.appDel.setObject(cheerPair, forKey: dictKey)
        self.appDel.synchronize()
    }
    
    func getRunnerLocation(trackedRunner: PFUser, result:(runnerLoc: CLLocationCoordinate2D) -> Void) {
        
        var runnerUpdate = CLLocationCoordinate2D()
        let now = NSDate()
        let seconds:NSTimeInterval = -60
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "CurrRunnerLocation")
        
        query.orderByDescending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
        query.whereKey("user", equalTo: trackedRunner)
        query.findObjectsInBackgroundWithBlock {
            (runnerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(runnerObjects!.count) updates.")
                if let runnerObjects = runnerObjects {
                    for object in runnerObjects {
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
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
}