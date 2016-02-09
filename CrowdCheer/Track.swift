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
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func getRunner(result:(runnerObjectID: String) -> Void)
    func getRunnerLocation(trackedRunnerID: String, result:(runnerLoc: CLLocationCoordinate2D) -> Void)
    func getRunnerPath(runner: PFUser) -> Array<PFGeoPoint>
    
}

class ContextPrimer: NSObject, Prime, CLLocationManagerDelegate {
    
    var user: PFUser
    var runner: PFUser
    var runnerObjID: String
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        self.user = PFUser.currentUser()
        self.runner = PFUser()
        self.runnerObjID = ""
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
    
    func getRunner(result:(runnerObjectID: String) -> Void) {
        //query Cheers class for spectator's runner commitment and retrieve runner object
        
        self.runner = PFUser()
        let now = NSDate()
        let seconds:NSTimeInterval = -600 //NOTE: called every second when tracking, so we get an empty query after 60 seconds. ideally, interval would last as long as you are committed to a runner, but then the query might find your last committed runner and your current, so then pull the most recent of the list?
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "Cheers")
        
        //NOTE: query just uses last runner on list of commitments, maybe should cleverly select a runner if we support multiple commitments, like if you check of all the people you want to cheer for, what if we display the ones in the ideal "start" range?
        query.orderByAscending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //cheers updated in the last 10 minutes
        query.whereKey("cheerer", equalTo: self.user)
        
        query.findObjectsInBackgroundWithBlock {
            (cheerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(cheerObjects!.count) cheers.")
                if let cheerObjects = cheerObjects {
                    for cheer in cheerObjects {
                        
                        let runnerObject = (cheer as! PFObject)["runner"] as! PFUser
                        self.runner = runnerObject
                        self.runnerObjID = self.runner.objectId
                    }
                }
                print ("Runner: ", self.runner)
                result(runnerObjectID: self.runnerObjID)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \(error!.userInfo)")
                result(runnerObjectID: self.runnerObjID)
            }
        }
    }
    
    func getRunnerLocation(trackedRunnerID: String, result:(runnerLoc: CLLocationCoordinate2D) -> Void) {
        
        let trackedRunner = PFQuery.getUserObjectWithId(trackedRunnerID)
        var runnerUpdate = CLLocationCoordinate2D()
        let now = NSDate()
        let seconds:NSTimeInterval = -60
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "CurrRunnerLocation")
        print("trackedRunner: ", trackedRunner)
        
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
                print ("Runner update: ", runnerUpdate)
                result(runnerLoc: runnerUpdate)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \(error!.userInfo)")
                result(runnerLoc: runnerUpdate)
            }
        }
    }
    
    func getRunnerPath(runner: PFUser) -> Array<PFGeoPoint> {
        let runnerPath:Array<PFGeoPoint> = []
        return runnerPath
    }
}