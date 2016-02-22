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
import AudioToolbox

class CheerViewController: UIViewController, CLLocationManagerDelegate {
    

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bibLabel: UILabel!
    @IBOutlet weak var outfit: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var lookBanner: UILabel!
    @IBOutlet weak var cheerBanner: UILabel!
    @IBOutlet weak var nearBanner: UILabel!
    
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var runnerTrackerTimer: NSTimer = NSTimer()
    var runner: PFUser = PFUser()
    var runnerName: String = ""
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var contextPrimer = ContextPrimer()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.distanceLabel.hidden = true
        self.nearBanner.hidden = true
        self.lookBanner.hidden = true
        self.cheerBanner.hidden = true
        
        //update the runner profile info & notify
        getRunnerProfile()
        
        
        
        //every second, update the distance and map with the runner's location
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
            self.runnerPath.append(self.runnerLastLoc)
            let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
            let distance = (self.locationMgr.location?.distanceFromLocation(runnerCLLoc))!
            updateBanner(runnerCLLoc)
            self.distanceLabel.text = String(format: " %.02f", distance) + "m away"
            self.distanceLabel.hidden = false
        }
    }
    
    func getRunnerProfile() {
        
        self.contextPrimer.getRunner(){ (runnerObjectID) -> Void in
            //update runner name, bib #, picture
            print("runnerObjID: ", runnerObjectID)
            self.runner = PFQuery.getUserObjectWithId(runnerObjectID)
            self.runnerName = (self.runner.valueForKey("name"))! as! String
            let runnerBib = (self.runner.valueForKey("bibNumber"))!
            let runnerOutfit = (self.runner.valueForKey("outfit"))!
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
            
            self.nameLabel.text = self.runnerName
            self.bibLabel.text = "Bib #: " + (runnerBib as! String)
            self.outfit.text = "Wearing: " + (runnerOutfit as! String)
            
            //notify user
            //if user is in background:
            //if user is active:
//            self.sendLocalNotification()
            
        }
    }
    
    func updateBanner(location: CLLocation) {
        
        let distanceCurr = (self.locationMgr.location?.distanceFromLocation(location))!
        if self.runnerPath.count > 1 {
            let coordinatePrev = self.runnerPath[self.runnerPath.count-2]
            let locationPrev = CLLocation(latitude: coordinatePrev.latitude, longitude: coordinatePrev.longitude)
            let distancePrev = (self.locationMgr.location?.distanceFromLocation(locationPrev))!
            
            print("prev: ", distancePrev)
            print("curr: ", distanceCurr)
            
            if distancePrev >= distanceCurr {
                
                if distanceCurr>50 {
                    self.nearBanner.text = self.runnerName + " is nearby!"
                    self.nearBanner.hidden = false
                    self.lookBanner.hidden = true
                    self.cheerBanner.hidden = true
                }
                    
                else if distanceCurr<=50 && distanceCurr>25 {
                    self.lookBanner.text = "LOOK FOR " + self.runnerName.capitalizedString + "!"
                    self.nearBanner.hidden = true
                    self.lookBanner.hidden = false
                    self.cheerBanner.hidden = true
                }
                    
                else if distanceCurr<=25 {
                    self.cheerBanner.text = "CHEER FOR " + self.runnerName.capitalizedString + "!"
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.nearBanner.hidden = true
                    self.lookBanner.hidden = true
                    self.cheerBanner.hidden = false
                }
                    
                else {
                    self.nearBanner.text = self.runnerName + " is nearby!"
                    self.nearBanner.hidden = false
                    self.lookBanner.hidden = true
                    self.cheerBanner.hidden = true
                }
            }
                
            else if distancePrev < distanceCurr {
                self.nearBanner.text = self.runnerName + " has passed by."
                self.nearBanner.hidden = false
                self.lookBanner.hidden = true
                self.cheerBanner.hidden = true
            }
                
            else {
                self.nearBanner.hidden = true
                self.lookBanner.hidden = true
                self.cheerBanner.hidden = true
            }

        }
        
        else {
            self.nearBanner.text = self.runnerName + " is nearby!"
            self.nearBanner.hidden = false
            self.lookBanner.hidden = true
            self.cheerBanner.hidden = true
        }
    }
    
//    func sendLocalNotification() {
//        let localNotification = UILocalNotification()
//        localNotification.alertBody = "Time to cheer for " + self.runnerName + "!"
//        localNotification.soundName = UILocalNotificationDefaultSoundName
//        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
//        
//        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
//    }
    
    func sendAlert() {
        
    }
}