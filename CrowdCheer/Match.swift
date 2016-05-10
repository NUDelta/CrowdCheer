//
//  Match.swift
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
    var location: CLLocation! {get set}
    var areRunnersNearby: Bool {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func checkCheerZone(result:(runnerLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void)
}

protocol Select: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation! {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func preselectRunners(runnerLocations: Dictionary<PFUser, PFGeoPoint>) -> Dictionary<PFUser, PFGeoPoint>
    func selectRunner(runner: PFUser, result:(cheerSaved: Bool) -> Void)
}

class NearbyRunners: NSObject, Trigger, CLLocationManagerDelegate {
//This class handles how a spectator monitors any runners around them
    
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation!
    var areRunnersNearby: Bool
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        location = locationMgr.location! //NOTE: occasionally returns nil
        areRunnersNearby = false
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = manager.location!
    }
    
    func checkCheerZone(result:(runnerLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void) {
        
        //query & return runners' locations from parse (recently updated & near me)
        let geoPoint = PFGeoPoint(location: location)
        var runnerUpdates = [PFUser: PFGeoPoint]()
        var runnerLocs:Array<AnyObject> = []
        let now = NSDate()
        let seconds:NSTimeInterval = -60
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "CurrRunnerLocation")
        
        query.orderByDescending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 2.0) //runners within 2 km of me
        query.findObjectsInBackgroundWithBlock {
            (runnerObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(runnerObjects!.count) runners nearby.")
                
                if let runnerObjects = runnerObjects {
                    for object in runnerObjects {
                        
                        let runner = (object as! PFObject)["user"] as! PFUser
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
                        runnerUpdates[runner] = location
                        runnerLocs.append(location)
                    }
                }
                print ("Runner dictionary: ", runnerLocs)
                
                if runnerLocs.isEmpty != true {
                    print("runnerLocs has a runner")
                    self.areRunnersNearby = true
                }
                else {
                    print("runnerLocs is empty")
                    self.areRunnersNearby = false
                }
                
                result(runnerLocations: runnerUpdates)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \(error!.userInfo)")
                result(runnerLocations: runnerUpdates)
            }
        }
    }
}

class SelectedRunners: NSObject, Select, CLLocationManagerDelegate {
//This class handles how a spectator monitors any runners around them
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var location: CLLocation!
    let appDel = NSUserDefaults()
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.Fitness
        locationMgr.distanceFilter = 1;
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = manager.location!
    }
    
    func preselectRunners(runnerLocations: Dictionary<PFUser, PFGeoPoint>) -> Dictionary<PFUser, PFGeoPoint> {
        let selectedRunners = runnerLocations
        return selectedRunners
        
    }
    
    func selectRunner(runner: PFUser, result:(cheerSaved: Bool) -> Void ) {
        
        
        //save runner/spectator pair to global dictionary
        var cheerPair = [String: String]()
        cheerPair[PFUser.currentUser().objectId] = runner.objectId
        appDel.setObject(cheerPair, forKey: dictKey)
        appDel.synchronize()
        
        
        //save runner/spectator pair as a cheer object to parse
        let cheer = PFObject(className:"Cheers")
        var isCheerSaved = Bool()
        cheer["runner"] = runner
        cheer["spectator"] = PFUser.currentUser()
        cheer.saveInBackgroundWithBlock { (_success:Bool, _error:NSError?) -> Void in
            if _error == nil
            {
                isCheerSaved = true
                print("cheer object saved: \(isCheerSaved)")
                result(cheerSaved: isCheerSaved)
            }
        }
    }
}