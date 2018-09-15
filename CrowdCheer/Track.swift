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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func getRunner() -> PFUser
    func getRunnerLocation(_ trackedRunner: PFUser, result:@escaping(_ runnerLoc: CLLocationCoordinate2D) -> Void)
    func spectatorChoseToSupport(_ runner: PFUser, didChooseToCheer: Bool)
    
}

class ContextPrimer: NSObject, Prime, CLLocationManagerDelegate {
    
    var user: PFUser
    var runner: PFUser
    var runnerObjID: String
    var locationMgr: CLLocationManager
    var location: CLLocation!
    let appDel = UserDefaults()
    
    //for Latency handling
    var currLoc = PFGeoPoint()
    var calcRunnerLoc = CLLocationCoordinate2D()
    var prevLocLat = 0.0
    var prevLocLon = 0.0
    var prevLocActualTime = Date()
    var actualTime = Date()
    var setTime = Date()
    var getTime = Date()
    var speed = 0.0
    
    //for runner details
    var pace = ""
    var distance = 0.0
    var duration = ""
    
    
    override init(){
        user = PFUser.current()!
        runner = PFUser()
        runnerObjID = "dummy"
        locationMgr = CLLocationManager()
        location = locationMgr.location!
        
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
        location = manager.location!
    }
    
    func getRunner() -> PFUser {
        
        print("inside getRunner")
        
        let pairDict = appDel.dictionary(forKey: dictKey)
        runnerObjID = pairDict![PFUser.current()!.objectId!] as! String
        
        let query = PFUser.query()
        query?.fromLocalDatastore()

        do {
            runner = try query?.getObjectWithId(runnerObjID) as! PFUser
        }

        catch {
            print("ERROR: cannot find runner object in local data store")
            runner = PFUser()
        }
        return runner
    }
    
    func resetRunner() {
        var cheerPair = [String: String]()
        cheerPair[PFUser.current()!.objectId!] = ""
        appDel.set(cheerPair, forKey: dictKey)
        appDel.synchronize()
        
        do {
            try runner.unpin(withName: "trackedRunner")
            print("did unpin trackedRunner")
        }
        catch {
            print("ERROR: could not unpin trackedRunner")
        }
        
    }
    
    func getRunnerLocation(_ trackedRunner: PFUser, result:@escaping (_ runnerLoc: CLLocationCoordinate2D) -> Void) {
        print("#####################")
        print("getrunnerloc running")
        
        var runnerUpdate = CLLocationCoordinate2D()
        let now = Date()
        let seconds:TimeInterval = -30
        let xSecondsAgo = now.addingTimeInterval(seconds)
        let query = PFQuery(className: "CurrRunnerLocation")
        
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 30 seconds
        query.whereKey("user", equalTo: trackedRunner)
        query.order(byDescending: "updatedAt")
        query.findObjectsInBackground {
            (runnerObjects: [PFObject]?, error: Error?) -> Void in
            
            if error == nil {
                // Found at least one runner
                print("Successfully retrieved \(runnerObjects!.count) updates.")
                if let runnerObjects = runnerObjects {
                    for object in runnerObjects {
                        self.currLoc = (object )["location"] as! PFGeoPoint
                        self.prevLocLat = (object )["prevLocLat"] as! Double
                        self.prevLocLon = (object)["prevLocLon"] as! Double
                        self.speed = (object)["speed"] as! Double
                        self.actualTime = (object)["time"] as! Date
                        self.setTime = object.updatedAt!
                        self.getTime = Date()
                        self.distance = (object)["distance"] as! Double
                        self.duration = (object)["duration"] as! String
                        self.pace = (object)["pace"] as! String

                        runnerUpdate = CLLocationCoordinate2DMake(self.currLoc.latitude, self.currLoc.longitude)
                    }
                }
                
                result(runnerUpdate)
            }
            else {
                // Query failed, load error
                print("ERROR: \(error!) \((error! as NSError).userInfo)")
                runnerUpdate = CLLocationCoordinate2DMake(self.currLoc.latitude, self.currLoc.longitude)
                result(runnerUpdate)
            }
        }
    }
    
    
    func spectatorChoseToSupport(_ runner: PFUser, didChooseToCheer: Bool) {
            
        //query Cheer object using spectatorID, runnerID
        //update object with field didCheer & corresponding value
        let query = PFQuery(className: "Cheers")
        
        query.whereKey("runner", equalTo: runner)
        query.whereKey("spectator", equalTo: user)
        query.order(byDescending: "updatedAt")
        query.getFirstObjectInBackground {
            (cheer: PFObject?, error: Error?) -> Void in
            if error == nil {
                if let cheer = cheer {
                    cheer["didChooseToCheer"] = didChooseToCheer
                    cheer.saveInBackground()
                }
            } else {
                print(error!)
            }
        }
    }
    
    func handleLatency(_ runner: PFUser, actualTime: Date, setTime: Date, getTime: Date, showTime: Date) -> (delay: TimeInterval, calculatedRunnerLoc: CLLocationCoordinate2D) {
    
        print("handling latency - track")
        let latency = PFObject(className:"Latency")
        
        let now = Date()
        let delay = now.timeIntervalSince(actualTime)
        let previousLoc = CLLocationCoordinate2DMake(self.prevLocLat, self.prevLocLon)
        let currentLoc = CLLocationCoordinate2DMake(self.currLoc.latitude, self.currLoc.longitude)
        self.calcRunnerLoc = currentLoc
        
        let distTraveled = calculateDistTraveled(delay, speed: self.speed)
        let bearing = calculateBearing(previousLoc, coorB: currentLoc)
        self.calcRunnerLoc = calculateLocation(currentLoc, bearing: bearing, distance: distTraveled)
        
        
        latency["spectator"] = self.user
        latency["runner"] = runner
        latency["actualTime"] = actualTime
        latency["setTime"] = setTime
        latency["getTime"] = getTime
        latency["showTime"] = now
        latency["totalDelay"] = delay
        latency.saveEventually()
        
        return (delay, calcRunnerLoc)
    }
    
    func calculateDistTraveled(_ delay: TimeInterval, speed: Double) -> Double {
        
        //calculate additional distance based on second delay + pace
        let distTraveled = speed*delay
        print("calculated distance traveled: \(distTraveled)")
        return distTraveled
    }
    
    func calculateBearing(_ coorA: CLLocationCoordinate2D, coorB: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: coorA.latitude, longitude: coorA.longitude)
        let locB = CLLocation(latitude: coorB.latitude, longitude: coorB.longitude)
        
        let bearing = bearingDegrees(locA, locB: locB)
        return bearing
    }
    
    func calculateLocation(_ runnerLoc: CLLocationCoordinate2D, bearing: Double, distance: Double) -> CLLocationCoordinate2D {
        //generate new loc point based on original loc + distance + bearing
        
        var calcRunnerLoc = runnerLoc
        let earthRadius = 6372797.6
        
        let lat1 = DegreesToRadians(runnerLoc.latitude)
        let lon1 = DegreesToRadians(runnerLoc.longitude)
        
        var lat2 = asin(sin(lat1)*cos(distance/earthRadius) + cos(lat1)*sin(distance/earthRadius)*cos(bearing))
        var lon2 = lon1 + atan2(sin(bearing)*sin(distance/earthRadius)*cos(lat1), cos(distance/earthRadius) - sin(lat1)*sin(lat2))
        
        lat2 = RadiansToDegrees(lat2)
        lon2 = RadiansToDegrees(lon2)
        
        calcRunnerLoc = CLLocationCoordinate2DMake(lat2, lon2)
        
        return calcRunnerLoc
    }
    
    func DegreesToRadians(_ degrees: Double ) -> Double {
        return degrees * .pi / 180
    }
    
    func RadiansToDegrees(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
    
    
    func bearingRadian(_ locA: CLLocation, locB:CLLocation) -> Double {
        
        let lat1 = DegreesToRadians(locA.coordinate.latitude)
        let lon1 = DegreesToRadians(locA.coordinate.longitude)
        
        let lat2 = DegreesToRadians(locB.coordinate.latitude);
        let lon2 = DegreesToRadians(locB.coordinate.longitude);
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    func bearingDegrees(_ locA: CLLocation, locB:CLLocation) -> Double{
        return   RadiansToDegrees(bearingRadian(locA, locB: locB))
    }
}
