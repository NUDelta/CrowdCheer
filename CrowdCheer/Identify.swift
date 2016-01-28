//
//  Identify.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import Parse


protocol Trigger: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func checkCheerZone(result:(runnerLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void)
}

protocol Select: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func preselectRunners() -> Dictionary<PFUser, PFGeoPoint>
}

class NearbyRunners: NSObject, Trigger, CLLocationManagerDelegate {
//This class handles how a cheerer monitors any runners around them
    
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        self.user = PFUser.currentUser()
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
    
    func checkCheerZone(result:(runnerLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void) {
        
        //query & return runners' locations from parse (recently updated & near me)
        let geoPoint = PFGeoPoint(location: location)
        var runnerUpdates = [PFUser: PFGeoPoint]()
        var runnerLocs:Array<AnyObject> = []
//        var runner:PFUser = PFUser.currentUser()
        let now = NSDate()
        let seconds:NSTimeInterval = -600
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "CurrRunnerLocation")
        
        query.orderByDescending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 0.5) //runners within 500 meters of me
        query.findObjectsInBackgroundWithBlock {
            (runnerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(runnerObjects!.count) scores.")
                //CURRENTLY: Walk through runners, save locations to a separate array
                //SHOULD: Walk through objects, extract runners, create dictionary of <Runner Object, Curr Location> entries
                if let runnerObjects = runnerObjects {
                    for object in runnerObjects {
                        print("Runner Entry: ", object)
                        
//                        object.fetchIfNeededInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
//                            runner = (object?["user"] as? PFUser)!
//                        })
                        
                        let runner = (object as! PFObject)["user"] as! PFUser
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
                        print("runner is  ", runner)
                        print ("runner's loc is: ", location)
                        runnerUpdates[runner] = location
                        runnerLocs.append(location)
                    }
                }
                print ("Runner Locs: ", runnerLocs)
                result(runnerLocations: runnerUpdates)
            }
            else {
                // Query failed, load error
                print("Error: \(error!) \(error!.userInfo)")
                result(runnerLocations: runnerUpdates)
            }
        }
    }
}
