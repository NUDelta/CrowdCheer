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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func isNetworkReachable() -> Bool
    func monitorUserLocation()
    func updateUserPath(_ interval: Int)
    func updateUserLocation()
    func enableBackgroundLoc()
}


//the RunnerMonitor Class specifically monitors runner stats (current location, movement, performance)
class RunnerMonitor: NSObject, Monitor, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.current()!
    var locationMgr: CLLocationManager
    var startRegionState: NSString
    var startLoc: CLLocation!
    var lastLoc: CLLocation!
    var distance: Double
    var pace: String
    var speed: Double
    var duration: NSInteger
    
    override init(){
        self.user = PFUser.current()!
        self.locationMgr = CLLocationManager()
        self.startRegionState = "unknown"
        self.distance = 0.0
        self.pace = ""
        self.speed = 0.0
        self.duration = 0
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.fitness
        self.locationMgr.distanceFilter = 1;
        if #available(iOS 9.0, *) {
            self.locationMgr.allowsBackgroundLocationUpdates = true
        }
        self.locationMgr.pausesLocationUpdatesAutomatically = true
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if self.startLoc == nil {
            startLoc = locations.first!
        }
        else {
            let lastDist = lastLoc.distance(from: locations.last!)
            
            self.distance += lastDist
        }
        self.lastLoc = locations.last
        
    }
    
    func isNetworkReachable() -> Bool {
        let reachability = Reachability()!
        
        if reachability.isReachable {
            if reachability.isReachableViaWiFi {
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
    
    
    func createStartRegion(_ startLine: CLLocationCoordinate2D) -> CLCircularRegion {
        let region = CLCircularRegion(center: startLine, radius: 100.0, identifier: "startRegion")
        region.notifyOnEntry = true
        return region
        
    }
    
    func createFinishRegion(_ finishLine: CLLocationCoordinate2D) -> CLCircularRegion {
        let region = CLCircularRegion(center: finishLine, radius: 100.0, identifier: "finishRegion")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    func startMonitoringRegion(_ region: CLCircularRegion) {
        
        locationMgr.startMonitoring(for: region)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        locationMgr.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        //called whenever there is a boundary transition + with requestStateForRegion
        
        if (state == CLRegionState.inside) {
            print("inside region")
            startRegionState = "inside"
        }
        else if (state == CLRegionState.outside) {
            print("outside region")
        }
        else if (state == CLRegionState.unknown) {
            print("unknown region")
            startRegionState = "unknown"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if (region.identifier == "startRegion") {
            
        }
        else if (region.identifier == "finishRegion") {
            //do nothing
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if (region.identifier == "startRegion") {
            startRegionState = "exited"
            print("exited region: \(startRegionState)")
        }
        else if (region.identifier == "finishRegion") {
            
        }
    }
    
        
    func monitorUserLocation() {
        
        // [done] TODO: check if location manager has a valid location before creating geopoint, else skip
        if let currLoc = self.locationMgr.location {
            if CLLocationCoordinate2DIsValid(currLoc.coordinate) {
                print(currLoc.coordinate)
                let currentLoc:CLLocationCoordinate2D =  (currLoc.coordinate)
                print("current location is: ", currentLoc)
            }
        }
        
        // track & register changes in audio output routes
        let route = AVAudioSession.sharedInstance().currentRoute.outputs
        print("audio route: \(route)")
        NotificationCenter.default.addObserver(self, selector: #selector(RunnerMonitor.audioSessionRouteChanged(_:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
    }
    
    func updateUserLocation() {
        // [done] TODO: check if location manager has a valid location before creating geopoint, else skip
        if let currLoc = self.locationMgr.location {
            if CLLocationCoordinate2DIsValid(currLoc.coordinate) {
                let loc:CLLocationCoordinate2D =  currLoc.coordinate
                let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
                self.speed = self.distance/Double(self.duration)
                self.pace = MathController.stringifyAvgPace(fromDist: Float(self.distance), overTime:self.duration)
                
                let query = PFQuery(className: "CurrRunnerLocation")
                query.whereKey("user", equalTo: self.user)
                // [done] TODO: check if currLoc is valid before trying to create a new parse object. --> this might be ok actually, check with above TODO
                // cases: currLoc is valid with no error, currLoc is not valid (doesn't exist) with no error, currLoc is not valid with error
                query.getFirstObjectInBackground {
                    (currLoc: PFObject?, error: Error?) -> Void in
                    // error exists -> create a new item
                    if error != nil {
                        print(error!)
                        //add runner
                        let newCurrLoc = PFObject(className: "CurrRunnerLocation")
                        newCurrLoc["prevLocLat"] = geoPoint.latitude
                        newCurrLoc["prevLocLon"] = geoPoint.longitude
                        newCurrLoc["location"] = geoPoint
                        newCurrLoc["user"] = PFUser.current()
                        newCurrLoc["distance"] = self.metersToMiles(self.distance)
                        newCurrLoc["speed"] = self.speed
                        newCurrLoc["pace"] = self.pace
                        newCurrLoc["duration"] =  self.stringFromSeconds(self.duration)
                        newCurrLoc["time"] = Date()
                        newCurrLoc.saveInBackground()
                        
                    } else {
                        if let currLoc = currLoc { // no error and valid currLoc
                            let prevLoc = (currLoc)["location"] as! PFGeoPoint
                            currLoc["prevLocLat"] = prevLoc.latitude
                            currLoc["prevLocLon"] = prevLoc.longitude
                            currLoc["location"] = geoPoint
                            currLoc["user"] = PFUser.current()
                            currLoc["distance"] = self.metersToMiles(self.distance)
                            currLoc["speed"] = self.speed
                            currLoc["pace"] = self.pace
                            currLoc["duration"] = self.stringFromSeconds(self.duration)
                            currLoc["time"] = Date()
                            currLoc.saveInBackground()
                        }
                    }
                }
            }
        }
    }
    
    func updateUserPath(_ interval: Int){
        // [done] TODO: check if location manager has a valid location before creating geopoint, else skip
        if let currLoc = self.locationMgr.location {
            CLLocationCoordinate2DIsValid(currLoc.coordinate) {
                let loc:CLLocationCoordinate2D =  currLoc.coordinate
                let geoPoint = PFGeoPoint(latitude: loc.latitude, longitude: loc.longitude)
                self.duration += interval
                self.speed = self.distance/(Double(self.duration) + 0.000001) //no nan
                self.pace = MathController.stringifyAvgPace(fromDist: Float(self.distance), overTime: duration)
                
                let object = PFObject(className:"RunnerLocations")
                print(geoPoint)
                print (user.objectId!)
                print(self.distance)
                print(self.duration)
                print(self.pace)
                print(self.speed)
                print(Date())
                object["location"] = geoPoint
                object["user"] = PFUser.current()
                object["distance"] = self.metersToMiles(self.distance)
                object["speed"] = self.speed
                object["pace"] = self.pace
                object["duration"] = self.stringFromSeconds(self.duration)
                object["time"] = Date()
                
                object.saveInBackground { (_success:Bool, _error:Error?) -> Void in
                    if _error == nil
                    {
                        print("location saved")
                    }
                    else {
                        print("err: \(String(describing: _error))")
                    }
                }
            }
        }
    }
    
    func resetRunnerData() {
        self.distance = 0.0
        self.pace = ""
        self.speed = 0.0
        self.duration = 0
    }
    
    func audioSessionRouteChanged(_ notification: Notification) {
        var userInfo = notification.userInfo
        let routeChangeReason = userInfo![AVAudioSessionRouteChangeReasonKey]
        print ("audio route change reason: \(String(describing: routeChangeReason))")
    }
    
    func enableBackgroundLoc() {
        
        var player = AVAudioPlayer()
        let soundPath = Bundle.main.url(forResource: "silence", withExtension: "mp3")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: soundPath!, fileTypeHint: "mp3")
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            print ("playing silent audio in background")
        }
        catch _ {
            return print("silence sound file not found")
        }
    }

    
    func stringFromSeconds(_ sec: NSInteger) -> String {
        let seconds = sec % 60
        let minutes = (sec / 60) % 60
        let hours = (sec / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func metersToMiles(_ meters: Double) -> Double {
        let km = meters/1000
        let mi = km*0.62137119
        return mi
    }
}


//the SpectatorMonitor Class specifically monitors Spectator stats (movement)
class SpectatorMonitor: NSObject, Monitor, CLLocationManagerDelegate {
    
    var user: PFUser = PFUser.current()!
    var locationMgr: CLLocationManager
    var startLoc: CLLocation!
    var lastLoc: CLLocation!
    var distance: Double
    var duration: NSInteger
    
    override init(){
        self.user = PFUser.current()!
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
        self.locationMgr.activityType = CLActivityType.fitness
        self.locationMgr.distanceFilter = 1;
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if self.startLoc == nil {
            startLoc = locations.first!
        }
        else {
            let lastDist = lastLoc.distance(from: locations.last!)
            
            self.distance += lastDist
        }
        self.lastLoc = locations.last
        
    }
    
    func isNetworkReachable() -> Bool {
        let reachability =  Reachability()!

        if reachability.isReachable {
            if reachability.isReachableViaWiFi {
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
        
        // [done] TODO: check if location manager has a valid location before creating geopoint, else skip
        if let currLoc = self.locationMgr.location {
            if CLLocationCoordinate2DIsValid(currLoc.coordinate) {
                let currentLoc:CLLocationCoordinate2D =  (currLoc.coordinate)
                print("current location is: ", currentLoc)
            }
        }
    }
    
    func updateUserLocation() {
        // [done] TODO: check if location manager has a valid location before creating geopoint, else skip
        if let currLoc = self.locationMgr.location {
            if CLLocationCoordinate2DIsValid(currLoc.coordinate) {
                let loc:CLLocationCoordinate2D =  currLoc.coordinate
                let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
                
                let query = PFQuery(className: "CurrSpectatorLocation")
                query.whereKey("user", equalTo: self.user)
                query.getFirstObjectInBackground {
                    (currLoc: PFObject?, error: Error?) -> Void in
                    if error != nil {
                        print(error!)
                        //add runner
                        let newCurrLoc = PFObject(className: "CurrSpectatorLocation")
                        newCurrLoc["prevLocLat"] = geoPoint.latitude
                        newCurrLoc["prevLocLon"] = geoPoint.longitude
                        newCurrLoc["location"] = geoPoint
                        newCurrLoc["user"] = PFUser.current()
                        newCurrLoc["distance"] = self.metersToMiles(self.distance)
                        newCurrLoc["duration"] =  self.stringFromSeconds(self.duration)
                        newCurrLoc["time"] = Date()
                        newCurrLoc.saveInBackground()
                        
                    } else if let currLoc = currLoc {
                        
                        let prevLoc = (currLoc)["location"] as! PFGeoPoint
                        currLoc["prevLocLat"] = prevLoc.latitude
                        currLoc["prevLocLon"] = prevLoc.longitude
                        currLoc["location"] = geoPoint
                        currLoc["user"] = PFUser.current()
                        currLoc["distance"] = self.metersToMiles(self.distance)
                        currLoc["duration"] = self.stringFromSeconds(self.duration)
                        currLoc["time"] = Date()
                        currLoc.saveInBackground()
                    }
                }
            }
        }
    }
    
    func updateUserPath(_ interval: Int){
        // [done] TODO: check if location manager has a valid location before creating geopoint, else skip
        if let currLoc = self.locationMgr.location {
            if CLLocationCoordinate2DIsValid(currLoc.coordinate) {
                let loc:CLLocationCoordinate2D =  self.locationMgr.location!.coordinate
                let geoPoint = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
                self.duration += interval
                
                let object = PFObject(className:"SpectatorLocations")
                object["location"] = geoPoint
                object["user"] = PFUser.current()
                object["distance"] = self.metersToMiles(self.distance)
                object["duration"] = self.stringFromSeconds(self.duration)
                object["time"] = Date()
                
                
                object.saveInBackground { (_success:Bool, _error:Error?) -> Void in
                    if _error == nil
                    {
                        print("location saved")
                    }
                }
            }
        }
    }
    
    func audioSessionRouteChanged(_ notification: Notification) {
        var userInfo = notification.userInfo
        let routeChangeReason = userInfo![AVAudioSessionRouteChangeReasonKey]
        print ("audio route change reason: \(String(describing: routeChangeReason))")
    }
    
    func enableBackgroundLoc() {
        
        var player = AVAudioPlayer()
        let soundPath = Bundle.main.url(forResource: "silence", withExtension: "mp3")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: soundPath!, fileTypeHint: "mp3")
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
        }
        catch _ {
            return print("silence sound file not found")
        }
    }
    
    func stringFromSeconds(_ sec: NSInteger) -> String {
        let seconds = sec % 60
        let minutes = (sec / 60) % 60
        let hours = (sec / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func metersToMiles(_ meters: Double) -> Double {
        let km = meters/1000
        let mi = km*0.62137119
        return mi
    }
}
