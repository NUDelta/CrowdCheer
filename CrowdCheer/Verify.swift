//
//  Verify.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 1/28/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import Parse
import AVFoundation


protocol Deliver: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func spectatorDidCheer(_ runner: PFUser, didCheer: Bool, audioFilePath: NSURL, audioFileName: String)
    func didSpectatorCheerRecently(_ runner: PFUser, result:@escaping(_ didCheerRecently: Bool) -> Void)
    func saveSpectatorCheer()
}

protocol Receive: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func saveRunnerCheer()
}

protocol React: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func trackPerformanceChange()
}

class VerifiedDelivery: NSObject, Deliver, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.current()!
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
        
    }
    
    func spectatorDidCheer(_ runner: PFUser, didCheer: Bool, audioFilePath: NSURL, audioFileName: String) {
        
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
                    //TODO: audio file not saving -- corrupted? always empty/28bits
                    let audioFileData: Data = try! Data(contentsOf: audioFilePath as URL)
                    let audioFile = PFFile(name: audioFileName, data: audioFileData)
                    cheer["cheerAudio"] = audioFile
                    cheer["didCheer"] = didCheer
                    cheer.saveInBackground()
                }
            } else {
                print(error!)
            }
        }
    }
    
    func didSpectatorCheerRecently(_ runner: PFUser, result:@escaping (_ didCheerRecently: Bool) -> Void) {
        //query Cheer object using spectatorID, runnerID
        //if spectator cheered for runner (didCheer=true) in last 15 min, return true
        
        let now = Date()
        let seconds:TimeInterval = -60*10 //demo: 10 min, regularly, 20 min
        let xSecondsAgo = now.addingTimeInterval(seconds)
        var didSpectatorCheer = false
        var didSpectatorCheerRecently = false
        
        let query = PFQuery(className: "Cheers")
        
        query.whereKey("runner", equalTo: runner)
        query.whereKey("spectator", equalTo: user)
        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 15 min
        query.getFirstObjectInBackground {
            (cheer: PFObject?, error: Error?) -> Void in
            if error == nil {
                if let cheer = cheer {
                    didSpectatorCheer = (cheer.value(forKey: "didCheer") != nil)
                    if didSpectatorCheer {
                        didSpectatorCheerRecently = true
                        print("++++++++ DID SPECTATOR CHEER RECENTLY -- yes \(didSpectatorCheerRecently) ++++++++")
                    }
                    else {
                        didSpectatorCheerRecently = false
                        print("++++++++ DID SPECTATOR CHEER RECENTLY -- no \(didSpectatorCheerRecently) ++++++++")
                    }
                }
            } else {
                print(error!)
                print("++++++++ DID SPECTATOR CHEER RECENTLY -- not yet \(didSpectatorCheerRecently) ++++++++")
            }
            result(didSpectatorCheerRecently)
        }
    }
    
    func saveSpectatorCheer() {
        
    }
    
    func getDocumentsDirectory() -> NSURL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSURL
    }

}

class VerifiedReceival: NSObject, Receive, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    override init(){
        user = PFUser.current()!
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
        
    }
    
    func saveRunnerCheer() {
        
    }
    
    func getDocumentsDirectory() -> NSURL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSURL
    }
}

class VerifiedReaction: NSObject, React, CLLocationManagerDelegate {
    
    var user: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        user = PFUser.current()!
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
        
    }
    func trackPerformanceChange() {
        
    }
}


