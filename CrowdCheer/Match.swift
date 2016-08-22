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
    
    func considerConvenience(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(conveniences: Dictionary<PFUser, Int>) -> Void)
    func considerNeed(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(needs: Dictionary<PFUser, Int>) -> Void)
    func considerAffinity(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(affinities: Dictionary<PFUser, Int>) -> Void)

}

protocol Select: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func preselectRunners(userLocations: Dictionary<PFUser, PFGeoPoint>, conveniences: Dictionary<PFUser, Int>, needs: Dictionary<PFUser, Int>, affinities: Dictionary<PFUser, Int>) -> Dictionary<PFUser, PFGeoPoint>
    func selectRunner(runner: PFUser, result:(cheerSaved: Bool) -> Void)
}

class NearbyRunners: NSObject, Trigger, CLLocationManagerDelegate {
//This class handles how a spectator monitors any runners around them
    
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var areUsersNearby: Bool
    var possibleRunners = [String : String]()
    var possibleRunnerCount: Int
    
    override init(){
        user = PFUser.currentUser()
        locationMgr = CLLocationManager()
        areUsersNearby = false
        possibleRunnerCount = 0
        possibleRunners = [:]
        
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
        
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 25.0) //runners within 25 km (~15mi) of me
        query.orderByDescending("updatedAt")
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
                        self.possibleRunners[runner.objectId] = runner.username
                        
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
    
    func saveRunnerCount(possibleRunnerCount: Int) {
        let newRunnerCount = PFObject(className: "NearbyRunnerCounts")
        newRunnerCount["spectator"] = user
        newRunnerCount["nearbyRunners"] = possibleRunnerCount
        
        user["possibleRunnerCount"] = possibleRunnerCount
        user.saveInBackground()
        newRunnerCount.saveInBackground()
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
        
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //spectators updated in the last 10 seconds
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 0.40) //spectators within 400m of me
        query.orderByDescending("updatedAt")
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
    var targetRunners = [String: Bool]()
    
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
    
    
    func considerConvenience(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(conveniences: Dictionary<PFUser, Int>) -> Void){
        var conveniences = [PFUser: Int]()
        
        for (runner, location) in userLocations {
            
            print(runner.username, location)
            let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
            
            //if runner is closer than 500m, set -1
            //if runner is between 500m-1000m, set to 10
            //if runner is between 1000m-2000m, set to 5
            
            if loc.distanceFromLocation(locationMgr.location!) < 500 {
                conveniences[runner] = -1
            }
            else if (loc.distanceFromLocation(locationMgr.location!) > 500) && (loc.distanceFromLocation(locationMgr.location!) < 1000) {
                conveniences[runner] = 10
            }
            else if (loc.distanceFromLocation(locationMgr.location!) > 1000) && (loc.distanceFromLocation(locationMgr.location!) < 500) {
                conveniences[runner] = 5
            }
        }
        
        result(conveniences: conveniences)
    }
    
    func considerNeed(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(needs: Dictionary<PFUser, Int>) -> Void) {
        var needs = [PFUser: Int]()
        
        //for each runner, retrieve all cheers
        //for each cheer, increment the runner's cheers
        //for cheer count between x and y, set need index for runner as z
        
        for (runner, location) in userLocations {
            
            print(runner.username, location)
            
            let query = PFQuery(className: "Cheers")
            //NOTE: currently counting all possible cheers, not spectator verified cheers
            query.whereKey("runner", equalTo: runner)
            query.findObjectsInBackgroundWithBlock{
                (cheerObjects: [AnyObject]?, error: NSError?) -> Void in
                if error == nil {
                    // Found at least one cheer
                    print("Successfully retrieved \(cheerObjects!.count) cheers.")
                    switch cheerObjects?.count {
                        
                    case 10?:
                        needs[runner] = 0
                    case 9?:
                        needs[runner] = 1
                    case 8?:
                        needs[runner] = 2
                    case 7?:
                        needs[runner] = 3
                    case 6?:
                        needs[runner] = 4
                    case 5?:
                        needs[runner] = 5
                    case 4?:
                        needs[runner] = 6
                    case 3?:
                        needs[runner] = 7
                    case 2?:
                        needs[runner] = 8
                    case 1?:
                        needs[runner] = 9
                    case 0?:
                        needs[runner] = 10
                    default:
                        needs[runner] = -1
                    }
                }
                else {
                    // Query failed, load error
                    print("ERROR: \(error!) \(error!.userInfo)")
                }
                result(needs: needs)
            }
        }
    }

    func considerAffinity(userLocations: Dictionary<PFUser, PFGeoPoint>, result:(affinities: Dictionary<PFUser, Int>) -> Void) {
        var affinities = [PFUser: Int]()
        
        if user.valueForKey("targetRunnerBib") == nil {
            print("no target runner")
        }
        
        else {
            let targetRunnerBibString = user.valueForKey("targetRunnerBib") as! String
            
            print("targetRunnerBibString: \(targetRunnerBibString)")
            let targetRunnerBibArr = targetRunnerBibString.componentsSeparatedByString(" ")
            print("bib array: \(targetRunnerBibArr)")
            
            let query = PFUser.query()
            query.whereKey("bibNumber", containedIn: targetRunnerBibArr)
            query.findObjectsInBackgroundWithBlock({ (targetRunners, error: NSError?) in
                for (runner, location) in userLocations {
                    for targetRunner in targetRunners {
                        
                        self.targetRunners[targetRunner.objectId] = false
                        print(runner.username, location)
                        
                        //if runner = target runner, +10 affinity
                        if runner.objectId == targetRunner.objectId {
                            affinities[runner] = 10
                            break
                        }
                        else {
                            affinities[runner] = 0
                        }
                    }
                }
                result(affinities: affinities)
            })
        }
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
    
    func preselectRunners(userLocations: Dictionary<PFUser, PFGeoPoint>, conveniences: Dictionary<PFUser, Int>, needs: Dictionary<PFUser, Int>, affinities: Dictionary<PFUser, Int>) -> Dictionary<PFUser, PFGeoPoint> {
        let selectedRunners = userLocations
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