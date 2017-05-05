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
    func saveSpectatorCheer()
    func getCheersDelivered(_ spectator: PFUser, result:@escaping (_ cheersCount: Int) -> Void)
}

protocol Receive: Any {
    var user: PFUser {get}
    var locationMgr: CLLocationManager {get}
    var location: CLLocation {get set}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func saveRunnerCheer()
    func getCheersReceived(_ runner: PFUser, result:@escaping (_ cheersCount: Int) -> Void)
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
        
        //query Cheer object using spectatorID, runnerID, maybe time?
        //update object with field didCheer & corresponding value
        
//        let now = NSDate()
//        let seconds:NSTimeInterval = -1200
//        let xSecondsAgo = now.dateByAddingTimeInterval(seconds)
        let query = PFQuery(className: "Cheers")
        
        query.whereKey("runner", equalTo: runner)
        query.whereKey("spectator", equalTo: user)
        query.order(byDescending: "updatedAt")
//        query.whereKey("updatedAt", greaterThanOrEqualTo: xSecondsAgo) //runners updated in the last 10 seconds
        query.getFirstObjectInBackground {
            (cheer: PFObject?, error: Error?) -> Void in
            if error != nil {
                print(error!)
            } else if let cheer = cheer {
                
                //NOTE: should save audio file to the class here too
                let audioFileData: Data = try! Data(contentsOf: audioFilePath as URL)
                let audioFile = PFFile(name: audioFileName, data: audioFileData)
                cheer["cheerAudio"] = audioFile
                cheer["didCheer"] = didCheer
                cheer.saveInBackground()
            }
        }
    }
    
    func saveSpectatorCheer() {
        
    }
    
    func getCheersDelivered(_ spectator: PFUser, result:@escaping (_ cheersCount: Int) -> Void) {
        //query Cheer objects using spectatorID + time
        
        var cheersCount = 0
        let now = NSDate()
        let hours:TimeInterval = -60*60*6
        let xHoursAgo = now.addingTimeInterval(hours)
        
        let query = PFQuery(className: "Cheers")

        query.whereKey("spectator", equalTo: spectator)
        query.order(byDescending: "updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xHoursAgo) //spectators updated in the last 6 hours
        query.findObjectsInBackground {
            (cheers: [PFObject]?, error: Error?) -> Void in
            if error != nil {
                print("ERROR: \(error!) \((error! as NSError).userInfo)")
                result(cheersCount)
            } else if let cheers = cheers {
                cheersCount = cheers.count
                print("cheers delivered count: \(cheersCount)")
                result(cheersCount)
            }
            
        }
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
    
    func getCheersReceived(_ runner: PFUser, result:@escaping (_ cheersCount: Int) -> Void) {
        //query Cheer objects using runner + time
        
        var cheersCount = 0
        let now = NSDate()
        let hours:TimeInterval = -60*60*6
        let xHoursAgo = now.addingTimeInterval(hours)
        
        let query = PFQuery(className: "Cheers")
        
        query.whereKey("runner", equalTo: runner)
        query.order(byDescending: "updatedAt")
        query.whereKey("updatedAt", greaterThanOrEqualTo: xHoursAgo) //spectators updated in the last 6 hours
        query.findObjectsInBackground {
            (cheers: [PFObject]?, error: Error?) -> Void in
            if error != nil {
                print("ERROR: \(error!) \((error! as NSError).userInfo)")
                result(cheersCount)
            } else if let cheers = cheers {
                cheersCount = cheers.count
                print("cheers delivered count: \(cheersCount)")
                result(cheersCount)
            }
            
        }
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


