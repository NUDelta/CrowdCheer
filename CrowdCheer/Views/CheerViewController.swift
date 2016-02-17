//
//  CheerViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/17/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Parse

class CheerViewController: UIViewController, CLLocationManagerDelegate {
    

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bibLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var lookBanner: UILabel!
    @IBOutlet weak var cheerBanner: UILabel!
    @IBOutlet weak var nearBanner: UILabel!
    
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var runnerTrackerTimer: NSTimer = NSTimer()
    var runner: PFUser = PFUser()
    var runnerLastLoc = CLLocationCoordinate2D()
    var contextPrimer = ContextPrimer()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //update the runner profile info
        //every second, update the distance and map with the runner's location
        
        getRunnerProfile()
        self.distanceLabel.hidden = true
        self.nearBanner.hidden = true
        self.lookBanner.hidden = true
        self.cheerBanner.hidden = true
        self.runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "trackRunner", userInfo: nil, repeats: true)
        self.contextPrimer = ContextPrimer()
        
        
    }
    
    func trackRunner() {
        //get latest loc and update map and distance label
        
        print("Tracking runner")
        let trackedRunnerID: String = self.runner.objectId
        
        self.contextPrimer.getRunnerLocation(trackedRunnerID) { (runnerLoc) -> Void in
            
            self.runnerLastLoc = runnerLoc
        }
        
        if (self.runnerLastLoc.latitude == 0.0 && self.runnerLastLoc.longitude == 0.0) {
            print("skipping coordinate")
        }
        else {
            let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
            let distance = (self.locationMgr.location?.distanceFromLocation(runnerCLLoc))!
            updateBanner(distance)
            self.distanceLabel.text = String(format: " %.02f", distance) + "m away"
            self.distanceLabel.hidden = false
        }
    }
    
    func getRunnerProfile() {
        
        self.contextPrimer.getRunner(){ (runnerObjectID) -> Void in
            //update runner name, bib #, picture
            print("runnerObjID: ", runnerObjectID)
            self.runner = PFQuery.getUserObjectWithId(runnerObjectID)
            let runnerName = (self.runner.valueForKey("name"))!
            let runnerBib = (self.runner.valueForKey("bibNumber"))!
            let userImageFile = self.runner["profilePic"] as? PFFile
            userImageFile!.getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        let image = UIImage(data:imageData)
                        self.profilePic.image = image
                    }
                }
            }
            
            self.nameLabel.text = runnerName as? String
            self.bibLabel.text = runnerBib as? String
            
        }
    }
    
    func updateBanner(distance: CLLocationDistance) {
        if distance>50 {
            self.nearBanner.text = self.nameLabel.text! + " is nearby!"
            self.nearBanner.hidden = false
            self.lookBanner.hidden = true
            self.cheerBanner.hidden = true
        }
    
        else if distance<=50 && distance>25 {
            self.lookBanner.text = "LOOK FOR " + self.nameLabel.text!.capitalizedString + "!"
            self.nearBanner.hidden = true
            self.lookBanner.hidden = false
            self.cheerBanner.hidden = true
        }
        
        else if distance<=25 {
            self.cheerBanner.text = "CHEER FOR " + self.nameLabel.text!.capitalizedString + "!"
            self.nearBanner.hidden = true
            self.lookBanner.hidden = true
            self.cheerBanner.hidden = false
        }
        
        else {
            self.nearBanner.text = self.nameLabel.text! + " is nearby!"
            self.nearBanner.hidden = false
            self.lookBanner.hidden = true
            self.cheerBanner.hidden = true
        }
        
    }
}