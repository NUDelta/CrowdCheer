//
//  Monitoring.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import Parse


protocol Monitoring: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    var runnersNearby: Array<PFObject> {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion)
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion)
    func monitorCheerZone(result:(runnerLocations: Array<AnyObject>?) -> Void) //create a geofence and print out current runners in my zone every 5 seconds
    
}

class MonitorRunners: NSObject, Monitoring, CLLocationManagerDelegate {
//This class handles how a cheerer monitors any runners around them
    
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var runnersNearby: Array<PFObject>
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        self.runnersNearby = []
        
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
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entering region")
    }
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exiting region")
    }
    
    func monitorCheerZone(result:(runnerLocations: Array<AnyObject>?) -> Void) {

        //set up a geofence around me
        let cheerZone = CLCircularRegion(center: location.coordinate, radius: 500, identifier: "cheerZone")
        locationMgr.startMonitoringForRegion(cheerZone)
        
        
        //query & return runners' locations from parse (recently updated & near me)
        let geoPoint = PFGeoPoint(location: location)
        var runnerLocs:Array<AnyObject> = []
        let now = NSDate()
        let interval:NSTimeInterval = -10
        let tenSecondsAgo = now.dateByAddingTimeInterval(interval)
        let query = PFQuery(className: "CurrRunnerLocation")
        
        query.orderByDescending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: tenSecondsAgo) //runners updated in the last 10 seconds
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 0.5) //runners within 500 meters of me
        query.findObjectsInBackgroundWithBlock {
            (runnerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(runnerObjects!.count) scores.")
                //CURRENTLY: Walk through runners, save locations to a separate array
                //SHOULD: Walk through objects, extract runners, create dictionary of <Runner Object, Curr Location> entries
                if let objects = runnerObjects {
                    for object in runnerObjects! {
                        print("Runner Entry: ", object)
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
                        runnerLocs.append(location)
                    }
                }
                print ("Runner Locs: ", runnerLocs)
                result(runnerLocations: runnerLocs)
            }
            else {
                // Query failed, load error
                print("Error: \(error!) \(error!.userInfo)")
                result(runnerLocations: runnerLocs)
            }
        }
    }
}


class MonitorMyRunner: NSObject, Monitoring, CLLocationManagerDelegate {
//This class handles how a cheerer monitors for their own runner(s)
    
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation
    var runnersNearby: Array<PFObject>
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        self.runnersNearby = []
        
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
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entering region")
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exiting region")
    }
    
    func monitorCheerZone(result:(runnerLocations: Array<AnyObject>?) -> Void) {
        //set up a geofence around me
        //query parse for my runner's location
        //check if my runner is in my geofence
        //if they are, print them out
    }
}

