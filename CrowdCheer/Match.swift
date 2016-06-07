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
    var areUsersNearby: Bool {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func checkProximityZone(result:(userLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void)
}

protocol Optimize: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    
    func considerConvenience(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(conveniences: Dictionary<PFUser, Double>) -> Void)
    func considerNeed(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(needs: Dictionary<PFUser, Int>) -> Void)
    func considerAffinity(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(affinities: Dictionary<PFUser, Int>) -> Void)

}

protocol Select: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func preselectRunners(runnerLocations: Dictionary<PFUser, PFGeoPoint>) -> Dictionary<PFUser, PFGeoPoint>
    func selectRunner(runner: PFUser, result:(cheerSaved: Bool) -> Void)
}

class NearbyRunners: NSObject, Trigger, CLLocationManagerDelegate {
//This class handles how a spectator monitors any runners around them
    
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var areUsersNearby: Bool
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        areUsersNearby = false
        
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
    }
    
    func checkProximityZone(result:(userLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void) {
        
        //query & return runners' locations from parse (recently updated & near me)
        let geoPoint = PFGeoPoint(location: locationMgr.location!)
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
                        
                        let runnerObj = (object as! PFObject)["user"] as! PFUser
                        let runner = PFQuery.getUserObjectWithId(runnerObj.objectId!)
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
                        runnerUpdates[runner] = location
                        runnerLocs.append(location)
                    }
                }
                print ("Runner dictionary: ", runnerLocs)
                
                if runnerLocs.isEmpty != true {
                    print("runnerLocs has a runner")
                    self.areUsersNearby = true
                }
                else {
                    print("runnerLocs is empty")
                    self.areUsersNearby = false
                }
                
                result(userLocations: runnerUpdates)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \(error!.userInfo)")
                result(userLocations: runnerUpdates)
            }
        }
    }
}


class NearbySpectators: NSObject, Trigger, CLLocationManagerDelegate {
    //This class handles how a spectator monitors any runners around them
    
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var areUsersNearby: Bool
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        areUsersNearby = false
        
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
    }
    
    func checkProximityZone(result:(userLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void) {
        
        //then look up their current location
        //create dictionary of spectators + their locations
        
        //query & return spectators' locations from parse (recently updated & near me)
        let geoPoint = PFGeoPoint(location: locationMgr.location!) //NOTE: nil here
        var spectatorUpdates = [PFUser: PFGeoPoint]()
        var spectatorLocs:Array<AnyObject> = []
        let now = NSDate()
        let seconds:NSTimeInterval = -60 //1 min
        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        
        let query = PFQuery(className: "CurrSpectatorLocation")
        
        query.orderByDescending("updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //spectators updated in the last 10 seconds
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 0.75) //spectators within 750m of me
        query.findObjectsInBackgroundWithBlock {
            (spectatorObjects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(spectatorObjects!.count) spectators nearby.")
                
                if let spectatorObjects = spectatorObjects {
                    for object in spectatorObjects {
                        
                        let spectatorObj = (object as! PFObject)["user"] as! PFUser
                        let spectator = PFQuery.getUserObjectWithId(spectatorObj.objectId!)
                        let location = (object as! PFObject)["location"] as! PFGeoPoint
                        spectatorUpdates[spectator] = location
                        spectatorLocs.append(location)
                    }
                }
                print ("Spectator dictionary: ", spectatorLocs)
                
                if spectatorLocs.isEmpty != true {
                    print("spectatorLocs has a spectator")
                    self.areUsersNearby = true
                }
                else {
                    print("spectatorLocs is empty")
                    self.areUsersNearby = false
                }
                
                result(userLocations: spectatorUpdates)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \(error!.userInfo)")
                result(userLocations: spectatorUpdates)
            }
        }
    }
}


class OptimizedRunners: NSObject, Optimize, CLLocationManagerDelegate {
//This class evaluates the convenience, affinity, and need associated with each possible pairing
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        
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
    }
    
    
    func considerConvenience(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(conveniences: Dictionary<PFUser, Double>) -> Void){
        let conveniences = [PFUser: Double]()
        result(conveniences: conveniences)
    }
    
    func considerNeed(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(needs: Dictionary<PFUser, Int>) -> Void) {
        let needs = [PFUser: Int]()
        result(needs: needs)
    }
    
    func considerAffinity(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(affinities: Dictionary<PFUser, Int>) -> Void) {
        let affinities = [PFUser: Int]()
        var targetRunner: PFUser = PFUser()
        
        let targetRunnerBib = user.valueForKey("targetRunnerBib")
        let query = PFUser.query()
        query.whereKey("bibNumber", equalTo: targetRunnerBib)
        query.getFirstObjectInBackgroundWithBlock { (targetRunners, error: NSError?) in
            targetRunner = targetRunners as! PFUser
            print("affinity runner username: \(targetRunner.username)")
        }
        
        for (runner, location) in userLocations {
            print ("userLocs entry in affinity: \(runner, location)")
//            print("affinity runner username: \(targetRunner.username)")
        }
        
        
        result(affinities: affinities)
    }
    
    func preselectRunners(runnerLocations: Dictionary<PFUser, PFGeoPoint>) -> Dictionary<PFUser, PFGeoPoint> {
        let selectedRunners = runnerLocations
        return selectedRunners
        
    }
}

class SelectedRunners: NSObject, Select, CLLocationManagerDelegate {
//This class handles how a spectator monitors any runners around them
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    let appDel = NSUserDefaults()
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        
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