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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func checkProximityZone(_ result:(_ userLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void)
}

protocol Optimize: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    
    func considerConvenience(_ userLocations: Dictionary<PFUser, PFGeoPoint>, result:(_ conveniences: Dictionary<PFUser, Int>) -> Void)
    func considerNeed(_ userLocations: Dictionary<PFUser, PFGeoPoint>, result:(_ needs: Dictionary<PFUser, Int>) -> Void)
    func considerAffinity(_ userLocations: Dictionary<PFUser, PFGeoPoint>, result:(_ affinities: Dictionary<PFUser, Int>) -> Void)

}

protocol Select: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func preselectRunners(_ userLocations: Dictionary<PFUser, PFGeoPoint>, conveniences: Dictionary<PFUser, Int>, needs: Dictionary<PFUser, Int>, affinities: Dictionary<PFUser, Int>) -> Dictionary<PFUser, PFGeoPoint>
    func selectRunner(_ runner: PFUser, result:(_ cheerSaved: Bool) -> Void)
}

class NearbyRunners: NSObject, Trigger, CLLocationManagerDelegate {
//This class handles how a spectator monitors any runners around them
    
    
    var user: PFUser = PFUser.current()!
    var locationMgr: CLLocationManager
    var areUsersNearby: Bool
    var possibleRunners = [String : String]()
    var possibleRunnerCount: Int
    var imagePath = ""
    
    override init(){
        user = PFUser.current()!
        locationMgr = CLLocationManager()
        areUsersNearby = false
        possibleRunnerCount = 0
        possibleRunners = [:]
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.fitness
        locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            locationMgr.allowsBackgroundLocationUpdates = true
        }
        locationMgr.pausesLocationUpdatesAutomatically = true
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func checkProximityZone(_ result:(_ userLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void) {
        
        //query & return runners' locations from parse (recently updated & near me)
        if locationMgr.location != nil {
            let geoPoint = PFGeoPoint(location: locationMgr.location!) //NOTE: crashes here - breakpoint crash (x4) - fixed with condiitonal?
            var runnerUpdates = [PFUser: PFGeoPoint]()
            var runnerLocs:Array<AnyObject> = []
            let now = Date()
            let seconds:TimeInterval = -60
            let xSecondsAgo = now.addingTimeInterval(seconds)
            let query = PFQuery(className: "CurrRunnerLocation")
            
            query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
            query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 45.0) //runners within 45 km (~27mi) of me
            query.order(byDescending: "updatedAt")
            query.findObjectsInBackground {
                (runnerObjects: [PFObject]?, error: Error?) -> Void in
                
                var runner: PFUser = PFUser()
                
                if error == nil {
                    // Found at least one runner
                    print("Successfully retrieved \(runnerObjects!.count) runners nearby.")
                    
                    if let runnerObjects = runnerObjects {
                        for object in runnerObjects {
                            
                            let runnerObj = (object )["user"] as! PFUser
                            do {
                                runner = try PFQuery.getUserObject(withId: runnerObj.objectId!) //NOTE: crashed here (on query) - crash
                            }
                            catch {
                                print("ERROR: unable to get runner")
                            }
                            let location = (object )["location"] as! PFGeoPoint
                            runnerUpdates[runner] = location
                            runnerLocs.append(location)
                            self.possibleRunners[runner.objectId!] = runner.username
                            
                        }
                    }
                    
                    if runnerLocs.isEmpty != true {
                        print("runnerLocs has a runner")
                        self.areUsersNearby = true
                    }
                    else {
                        print("runnerLocs is empty")
                        self.areUsersNearby = false
                    }
                    
                    result(runnerUpdates)
                }
                else {
                    // Query failed, load error
                    print("ERROR: \(error!) \((error! as NSError).userInfo)")
                    result(runnerUpdates)
                }
            }
        }
    }
    
    func getRunnerProfile(_ runnerObjID: String, result:(_ runnerProfile: Dictionary<String, AnyObject>) -> Void) {
        var runnerProfile = [String: AnyObject]()
        var runner: PFUser = PFUser()
        
        do {
            runner = try PFQuery.getUserObject(withId: runnerObjID)
        }
        catch {
            print("ERROR: unable to get runner")
        }
        let name = (runner.value(forKey: "name"))!
        runnerProfile["objectID"] = runnerObjID as AnyObject
        runnerProfile["name"] = name as AnyObject
        
        let userImageFile = runner["profilePic"] as? PFFile
        userImageFile!.getDataInBackground {
            (imageData: Data?, error: Error?) -> Void in
            if error == nil {
                if let imageData = imageData {
                    let fileManager = FileManager.default
                    self.imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(runner.username).jpg")
                    print(self.imagePath)
                    runnerProfile["profilePicPath"] = self.imagePath as AnyObject
                    fileManager.createFile(atPath: self.imagePath as String, contents: imageData, attributes: nil)
                }
            }
            result(runnerProfile)
        }
    }
    
    func saveRunnerCount(_ possibleRunnerCount: Int) {
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
    
    
    var user: PFUser = PFUser.current()!
    var locationMgr: CLLocationManager
    var areUsersNearby: Bool
    
    override init(){
        user = PFUser.current()!
        locationMgr = CLLocationManager()
        areUsersNearby = false
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.fitness
        locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            locationMgr.allowsBackgroundLocationUpdates = true
        }
        locationMgr.pausesLocationUpdatesAutomatically = true
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func checkProximityZone(_ result:(_ userLocations: Dictionary<PFUser, PFGeoPoint>?) -> Void) {
        
        //then look up their current location
        //create dictionary of spectators + their locations
        
        //query & return spectators' locations from parse (recently updated & near me)
        let geoPoint = PFGeoPoint(location: locationMgr.location!) //NOTE: nil here
        var spectatorUpdates = [PFUser: PFGeoPoint]()
        var spectatorLocs:Array<AnyObject> = []
        let now = Date()
        let seconds:TimeInterval = -60 //1 min
        let xSecondsAgo = now.addingTimeInterval(seconds)
        
        let query = PFQuery(className: "CurrSpectatorLocation")
        
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //spectators updated in the last 10 seconds
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: 0.50) //spectators within 500m of me
        query.order(byDescending: "updatedAt")
        query.findObjectsInBackground {
            (spectatorObjects: [PFObject]?, error: Error?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(spectatorObjects!.count) spectators nearby.")
                
                if let spectatorObjects = spectatorObjects {
                    var spectator: PFUser = PFUser()
                    
                    for object in spectatorObjects {
                        
                        let spectatorObj = (object )["user"] as! PFUser
                        do {
                            spectator = try PFQuery.getUserObject(withId: spectatorObj.objectId!)
                        }
                        catch {
                            print("ERROR: unable to get spectator")
                        }
                        let location = (object)["location"] as! PFGeoPoint
                        spectatorUpdates[spectator] = location //NOTE: crashes here - Seg Fault, Kernel Invalid Address (x2)
                        spectatorLocs.append(location)
                    }
                }
                
                if spectatorLocs.isEmpty != true {
                    print("spectatorLocs has a spectator")
                    self.areUsersNearby = true
                }
                else {
                    print("spectatorLocs is empty")
                    self.areUsersNearby = false
                }
                
                result(spectatorUpdates)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \((error! as NSError).userInfo)")
                result(spectatorUpdates)
            }
        }
    }
}


class OptimizedRunners: NSObject, Optimize, CLLocationManagerDelegate {
//This class evaluates the convenience, affinity, and need associated with each possible pairing
    
    var user: PFUser = PFUser.current()!
    var locationMgr: CLLocationManager
    var targetRunners = [String: Bool]()
    var generalRunners = [String]()
    
    override init(){
        user = PFUser.current()!
        locationMgr = CLLocationManager()
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.fitness
        locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            locationMgr.allowsBackgroundLocationUpdates = true
        }
        locationMgr.pausesLocationUpdatesAutomatically = true
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    
    func considerConvenience(_ userLocations: Dictionary<PFUser, PFGeoPoint>, result:(_ conveniences: Dictionary<PFUser, Int>) -> Void){
        var conveniences = [PFUser: Int]()
        
        for (runner, location) in userLocations {

            let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
            
            //if runner is closer than 500m, set -1
            //if runner is between 500m-1000m, set to 10
            //if runner is between 1000m-2000m, set to 5
            
            if loc.distance(from: locationMgr.location!) < 500 {
                conveniences[runner] = -1
            }
            else if (loc.distance(from: locationMgr.location!) > 500) && (loc.distance(from: locationMgr.location!) < 1000) {
                conveniences[runner] = 10
            }
            else if (loc.distance(from: locationMgr.location!) > 1000) && (loc.distance(from: locationMgr.location!) < 500) {
                conveniences[runner] = 5
            }
        }
        
        result(conveniences)
    }
    
    func considerNeed(_ userLocations: Dictionary<PFUser, PFGeoPoint>, result:(_ needs: Dictionary<PFUser, Int>) -> Void) {
        var needs = [PFUser: Int]()
        
        //for each runner, retrieve all cheers
        //for each cheer, increment the runner's cheers
        //for cheer count between x and y, set need index for runner as z
        
        for (runner, location) in userLocations {
            
            let query = PFQuery(className: "Cheers")
            //NOTE: currently counting all possible cheers, not spectator verified cheers
            query.whereKey("runner", equalTo: runner)
            query.findObjectsInBackground{
                (cheerObjects: [PFObject]?, error: Error?) -> Void in
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
                    print("ERROR: \(error!) \((error! as NSError).userInfo)")
                }
                result(needs)
            }
        }
    }

    func considerAffinity(_ userLocations: Dictionary<PFUser, PFGeoPoint>, result:(_ affinities: Dictionary<PFUser, Int>) -> Void) {
        var affinities = [PFUser: Int]()
        
        if user.value(forKey: "targetRunnerBib") == nil {
            print("no target runner")
        }
        
        else {
            let targetRunnerBibString = user.value(forKey: "targetRunnerBib") as! String
            
            let targetRunnerBibArr = targetRunnerBibString.components(separatedBy: " ")
            print("bib array: \(targetRunnerBibArr)")
            
            let query = PFUser.query()
            query!.whereKey("bibNumber", containedIn: targetRunnerBibArr)
            query!.findObjectsInBackground(block: { (targetRunners, error: Error?) in
                for (runner, location) in userLocations {
                    for targetRunner in targetRunners! {
                        
                        self.targetRunners[targetRunner.objectId!] = false
                        
                        //if runner = target runner, +10 affinity
                        if runner.objectId == targetRunner.objectId {
                            affinities[runner] = 10
                            self.targetRunners[targetRunner.objectId!] = true
                            break
                        }
                        else {
                            affinities[runner] = 0
                            if self.generalRunners.contains(runner.objectId!) {
                                //do nothing
                            }
                            else {
                                self.generalRunners.append(runner.objectId!)
                            }
                            
                        }
                        print("generalRunners within considerAffinity: \(self.generalRunners)")
                    }
                }
                result(affinities)
            })
        }
    }
    
    func preselectRunners(_ runnerLocations: Dictionary<PFUser, PFGeoPoint>) -> Dictionary<PFUser, PFGeoPoint> {
        let selectedRunners = runnerLocations //NOTE: Crashed here (query)
        return selectedRunners
        
    }
}

class SelectedRunners: NSObject, Select, CLLocationManagerDelegate {
//This class handles how a spectator monitors any runners around them
    
    var user: PFUser = PFUser.current()!
    var locationMgr: CLLocationManager
    let appDel = UserDefaults()
    
    override init(){
        user = PFUser.current()!
        locationMgr = CLLocationManager()
        
        //initialize location manager
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.activityType = CLActivityType.fitness
        locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            locationMgr.allowsBackgroundLocationUpdates = true
        }
        locationMgr.pausesLocationUpdatesAutomatically = true
        locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func preselectRunners(_ userLocations: Dictionary<PFUser, PFGeoPoint>, conveniences: Dictionary<PFUser, Int>, needs: Dictionary<PFUser, Int>, affinities: Dictionary<PFUser, Int>) -> Dictionary<PFUser, PFGeoPoint> {
        let selectedRunners = userLocations
        return selectedRunners
        
    }
    
    func selectRunner(_ runner: PFUser, result:(_ cheerSaved: Bool) -> Void ) {
        
        
        //save runner/spectator pair to global dictionary
        var cheerPair = [String: String]()
        cheerPair[PFUser.current()!.objectId!] = runner.objectId
        appDel.set(cheerPair, forKey: dictKey)
        appDel.synchronize()
        
        
        //save runner/spectator pair as a cheer object to parse
        let cheer = PFObject(className:"Cheers")
        var isCheerSaved = Bool()
        cheer["runner"] = runner
        cheer["spectator"] = PFUser.current()
        cheer.saveInBackground { (_success:Bool, _error:Error?) -> Void in
            if _error == nil
            {
                isCheerSaved = true
                print("cheer object saved: \(isCheerSaved)")
                result(isCheerSaved)
            }
        }
    }
}
