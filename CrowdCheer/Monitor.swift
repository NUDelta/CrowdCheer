//
//  Monitor.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 10/30/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation
import Parse


//the MONITOR protocol is used to monitor the status of all users
protocol Monitor: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var startLoc: CLLocation! {get set}
    var lastLoc: CLLocation! {get set}
    var distance: Double {get set}
    var duration: NSInteger {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func isNetworkReachable() -> Bool
    func monitorUserLocation()
    func updateUserPath(interval: Int)
    func updateUserLocation()
    func enableBackgroundLoc()
}


//the RunnerMonitor Class specifically monitors runner stats (current location, movement, performance)
class RunnerMonitor: NSObject, Monitor, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var startLoc: CLLocation!
    var lastLoc: CLLocation!
    var distance: Double
    var pace: NSString
    var speed: Double
    var duration: NSInteger
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.distance = 0.0
        self.pace = ""
        self.speed = 0.0
        self.duration = 0
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.Fitness
        self.locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            self.locationMgr.allowsBackgroundLocationUpdates = true
        }
        self.locationMgr.pausesLocationUpdatesAutomatically = true
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if self.startLoc == nil {
            startLoc = locations.first!
        }
        else {
            let lastDist = lastLoc.distanceFromLocation(locations.last!)
            
            self.distance += lastDist
        }
        self.lastLoc = locations.last
        
    }
    
    func isNetworkReachable() -> Bool {
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return false
        }
        
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                print("Reachable via WiFi")
                return true
            } else {
                print("Reachable via Cellular")
                return true
            }
        } else {
            print("Network not reachable")
            return false
        }
    }
    
    
    func createStartRegion(startLine: CLLocationCoordinate2D) -> CLCircularRegion {
        let region = CLCircularRegion(center: startLine, radius: 100.0, identifier: "startRegion")
        region.notifyOnEntry = true
        return region
        
    }
    
    func createFinishRegion(finishLine: CLLocationCoordinate2D) -> CLCircularRegion {
        let region = CLCircularRegion(center: finishLine, radius: 100.0, identifier: "finishRegion")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    func startMonitoringRegion(region: CLCircularRegion) {
        
        locationMgr.startMonitoringForRegion(region)
        
    }
    
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        locationMgr.requestStateForRegion(region)
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        
        if (state == CLRegionState.Inside) {
            print("inside region \(region.identifier)")
            //RunViewController().resetTracking()
            RunViewController().genericTestingNotification("currently inside region, start tracking")
        }
        else if (state == CLRegionState.Outside) {
            print("outside region \(region.identifier)")
        }
        else if (state == CLRegionState.Unknown) {
            print("unknown region \(region.identifier)")
            RunViewController().genericTestingNotification("region is unknown")
        }
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if (region.identifier == "startRegion") {
            print("start monitoring runner")
            //RunViewController().resetTracking()
            RunViewController().genericTestingNotification("just entered region, start tracking")
        }
        else if (region.identifier == "finishRegion") {
            //do nothing
        }
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if (region.identifier == "startRegion") {
            print("restart monitoring runner")
            //RunViewController().resetTracking()
            RunViewController().genericTestingNotification("just exited region, reset tracking")
        }
        else if (region.identifier == "finishRegion") {
            print("stop monitoring runner")
            
        }
    }
    
        
    func monitorUserLocation() {
        
        print(self.locationMgr.location!.coordinate)
        let currentLoc:CLLocationCoordinate2D =  (self.locationMgr.location!.coordinate)
        print("current location is: ", currentLoc)
        
        // track & register changes in audio output routes
        let route = AVAudioSession.sharedInstance().currentRoute.outputs
        print("audio route: \(route)")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RunnerMonitor.audioSessionRouteChanged(_:)), name: AVAudioSessionRouteChangeNotification, object: nil)
    }
    
    func updateUserLocation() {
        let loc:CLLocationCoordinate2D =  self.locationMgr.location!.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        self.speed = self.distance/Double(self.duration)
        self.pace = MathController.stringifyAvgPaceFromDist(Float(self.distance), overTime:self.duration)
        
        let query = PFQuery(className: "CurrRunnerLocation")
        query.whereKey("user", equalTo: self.user)
        query.getFirstObjectInBackgroundWithBlock {
            (currLoc: PFObject?, error: NSError?) -> Void in
            if error != nil {
                print(error)
                //add runner
                let newCurrLoc = PFObject(className: "CurrRunnerLocation")
                newCurrLoc["prevLocLat"] = geoPoint.latitude
                newCurrLoc["prevLocLon"] = geoPoint.longitude
                newCurrLoc["location"] = geoPoint
                newCurrLoc["user"] = PFUser.currentUser()
                newCurrLoc["distance"] = self.metersToMiles(self.distance)
                newCurrLoc["speed"] = self.speed
                newCurrLoc["pace"] = self.pace
                newCurrLoc["duration"] =  self.stringFromSeconds(self.duration)
                newCurrLoc["time"] = NSDate()
                newCurrLoc.saveInBackground()
                
            } else if let currLoc = currLoc {
                let prevLoc = (currLoc)["location"] as! PFGeoPoint
                currLoc["prevLocLat"] = prevLoc.latitude
                currLoc["prevLocLon"] = prevLoc.longitude
                currLoc["location"] = geoPoint
                currLoc["user"] = PFUser.currentUser()
                currLoc["distance"] = self.metersToMiles(self.distance)
                currLoc["speed"] = self.speed
                currLoc["pace"] = self.pace
                currLoc["duration"] = self.stringFromSeconds(self.duration)
                currLoc["time"] = NSDate()
                currLoc.saveInBackground()
            }
        }
    }
    
    func updateUserPath(interval: Int){
        
        let loc:CLLocationCoordinate2D =  self.locationMgr.location!.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        self.speed = self.distance/Double(self.duration)
        self.pace = MathController.stringifyAvgPaceFromDist(Float(self.distance), overTime: duration)
        self.duration += interval
        
        let object = PFObject(className:"RunnerLocations")
        print(geoPoint)
        print (user.objectId)
        print(self.distance)
        print(self.duration)
        print(self.pace)
        object["location"] = geoPoint
        object["user"] = PFUser.currentUser()
        object["distance"] = self.metersToMiles(self.distance)
        object["speed"] = self.speed
        object["pace"] = self.pace
        object["duration"] = self.stringFromSeconds(self.duration)
        object["time"] = NSDate()
        
        object.saveInBackgroundWithBlock { (_success:Bool, _error:NSError?) -> Void in
            if _error == nil
            {
                print("location saved")
            }
        }
    }
    
    func resetRunnerData() {
        self.distance = 0.0
        self.pace = ""
        self.speed = 0.0
        self.duration = 0
    }
    
    func audioSessionRouteChanged(notification: NSNotification) {
        var userInfo = notification.userInfo
        let routeChangeReason = userInfo![AVAudioSessionRouteChangeReasonKey]
        print ("audio route change reason: \(routeChangeReason)")
    }
    
    func enableBackgroundLoc() {
        
        var player = AVAudioPlayer()
        let soundPath = NSBundle.mainBundle().URLForResource("silence", withExtension: "mp3")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOfURL: soundPath!, fileTypeHint: "mp3")
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            print ("playing silent audio in background")
        }
        catch _ {
            return print("silence sound file not found")
        }
    }

    
    func stringFromSeconds(sec: NSInteger) -> String {
        let seconds = sec % 60
        let minutes = (sec / 60) % 60
        let hours = (sec / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func metersToMiles(meters: Double) -> Double {
        let km = meters/1000
        let mi = km*0.62137119
        return mi
    }
}


//the SpectatorMonitor Class specifically monitors Spectator stats (movement)
class SpectatorMonitor: NSObject, Monitor, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.currentUser()
    var locationMgr: CLLocationManager
    var startLoc: CLLocation!
    var lastLoc: CLLocation!
    var distance: Double
    var duration: NSInteger
    
    override init(){
        self.user = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.distance = 0.0
        self.duration = 0
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        if #available(iOS 9.0, *) {
            self.locationMgr.allowsBackgroundLocationUpdates = true
        }
        self.locationMgr.pausesLocationUpdatesAutomatically = true
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.Fitness
        self.locationMgr.distanceFilter = 1;
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if self.startLoc == nil {
            startLoc = locations.first!
        }
        else {
            let lastDist = lastLoc.distanceFromLocation(locations.last!)
            
            self.distance += lastDist
        }
        self.lastLoc = locations.last
        
    }
    
    func isNetworkReachable() -> Bool {
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return false
        }
        
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                print("Reachable via WiFi")
                return true
            } else {
                print("Reachable via Cellular")
                return true
            }
        } else {
            print("Network not reachable")
            return false
        }
    }
    
    func monitorUserLocation() {
        
        let currentLoc:CLLocationCoordinate2D =  (self.locationMgr.location!.coordinate)
        print("current location is: ", currentLoc)
    }
    
    func updateUserLocation() {
        let loc:CLLocationCoordinate2D =  self.locationMgr.location!.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        
        let query = PFQuery(className: "CurrSpectatorLocation")
        query.whereKey("user", equalTo: self.user)
        query.getFirstObjectInBackgroundWithBlock {
            (currLoc: PFObject?, error: NSError?) -> Void in
            if error != nil {
                print(error)
                //add runner
                let newCurrLoc = PFObject(className: "CurrSpectatorLocation")
                newCurrLoc["prevLocLat"] = geoPoint.latitude
                newCurrLoc["prevLocLon"] = geoPoint.longitude
                newCurrLoc["location"] = geoPoint
                newCurrLoc["user"] = PFUser.currentUser()
                newCurrLoc["distance"] = self.metersToMiles(self.distance)
                newCurrLoc["duration"] =  self.stringFromSeconds(self.duration)
                newCurrLoc["time"] = NSDate()
                newCurrLoc.saveInBackground()
                
            } else if let currLoc = currLoc {
                
                let prevLoc = (currLoc)["location"] as! PFGeoPoint
                currLoc["prevLocLat"] = prevLoc.latitude
                currLoc["prevLocLon"] = prevLoc.longitude
                currLoc["location"] = geoPoint
                currLoc["user"] = PFUser.currentUser()
                currLoc["distance"] = self.metersToMiles(self.distance)
                currLoc["duration"] = self.stringFromSeconds(self.duration)
                currLoc["time"] = NSDate()
                currLoc.saveInBackground()
            }
        }
    }
    
    func updateUserPath(interval: Int){
        
        let loc:CLLocationCoordinate2D =  self.locationMgr.location!.coordinate
        let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
        self.duration += interval
        
        let object = PFObject(className:"SpectatorLocations")
        object["location"] = geoPoint
        object["user"] = PFUser.currentUser()
        object["distance"] = self.metersToMiles(self.distance)
        object["duration"] = self.stringFromSeconds(self.duration)
        object["time"] = NSDate()
        
        
        object.saveInBackgroundWithBlock { (_success:Bool, _error:NSError?) -> Void in
            if _error == nil
            {
                print("location saved")
            }
        }
    }
    
    func audioSessionRouteChanged(notification: NSNotification) {
        var userInfo = notification.userInfo
        let routeChangeReason = userInfo![AVAudioSessionRouteChangeReasonKey]
        print ("audio route change reason: \(routeChangeReason)")
    }
    
    func enableBackgroundLoc() {
        
        var player = AVAudioPlayer()
        let soundPath = NSBundle.mainBundle().URLForResource("silence", withExtension: "mp3")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOfURL: soundPath!, fileTypeHint: "mp3")
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
        }
        catch _ {
            return print("silence sound file not found")
        }
    }
    
    func stringFromSeconds(sec: NSInteger) -> String {
        let seconds = sec % 60
        let minutes = (sec / 60) % 60
        let hours = (sec / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func metersToMiles(meters: Double) -> Double {
        let km = meters/1000
        let mi = km*0.62137119
        return mi
    }
}
