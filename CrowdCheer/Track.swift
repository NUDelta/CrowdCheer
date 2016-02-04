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
    func getRunner(result:(runnerObject: PFUser) -> Void)
//    func getRunnerLocation(runner: PFUser) -> CLLocation
    func getRunnerLocation(runner: PFUser, result:(runnerLoc: CLLocationCoordinate2D) -> Void)
    func getRunnerPath(runner: PFUser) -> Array<PFGeoPoint>
    
}

class ContextPrimer: NSObject, Prime, CLLocationManagerDelegate {
    
    var user: PFUser
    var runner: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        self.user = PFUser.currentUser()
        self.runner = PFUser()
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
    
    func getRunner(result:(runnerObject: PFUser) -> Void) {
        //query Cheers class for spectator's runner commitment and retrieve runner object
        
        var runner = PFUser()
        let now = NSDate()
        let seconds:NSTimeInterval = -60
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "Cheers")
        
        //NOTE: query just uses last runner on list of commitments, maybe should cleverly select a runner if we support multiple commitments, like if you check of all the people you want to cheer for, what if we display the ones in the ideal "start" range?
        query.orderByDescending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10
        query.whereKey("cheerer", equalTo: self.user)
        
        query.findObjectsInBackgroundWithBlock {
            (cheerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(cheerObjects!.count) cheers.")
                if let cheerObjects = cheerObjects {
                    for cheer in cheerObjects {
                        
                        let runnerObject = (cheer as! PFObject)["runner"] as! PFUser
                        runner = runnerObject
                    }
                }
                print ("Runner: ", runner)
                result(runnerObject: runner)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \(error!.userInfo)")
                result(runnerObject: runner)
            }
        }
    }
    
    func getRunnerLocation(runner: PFUser, result:(runnerLoc: CLLocationCoordinate2D) -> Void) {
        var runnerUpdate = CLLocationCoordinate2D()
        let now = NSDate()
        let seconds:NSTimeInterval = -3600
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "CurrRunnerLocation")
        
        query.orderByDescending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
        query.findObjectsInBackgroundWithBlock {
            (runnerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(runnerObjects!.count) updates.")
                if let runnerObjects = runnerObjects {
                    for object in runnerObjects {
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
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