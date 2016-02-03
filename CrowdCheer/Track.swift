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
    var location: CLLocation {get set}
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func getRunnerLocation() -> Dictionary<PFUser, PFGeoPoint>
    func getRunnerPath() -> Array<PFGeoPoint>
    
}

class contextPrimer: NSObject, Prime, CLLocationManagerDelegate {
    
    var user: PFUser
    var runner: PFUser
    var locationMgr: CLLocationManager
    var location: CLLocation
    
    override init(){
        self.user = PFUser.currentUser()
        self.runner = PFUser.currentUser()
        self.locationMgr = CLLocationManager()
        self.location = self.locationMgr.location!
        
        //initialize location manager
        super.init()
        self.locationMgr.delegate = self
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.activityType = CLActivityType.Fitness
        self.locationMgr.distanceFilter = 1;
        self.locationMgr.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    func getRunnerLocation() -> Dictionary<PFUser, PFGeoPoint> {
        let runnerUpdate = [PFUser: PFGeoPoint]()
        return runnerUpdate
    }
    
    func getRunnerPath() -> Array<PFGeoPoint> {
        let runnerPath:Array<PFGeoPoint> = []
        return runnerPath
    }
}