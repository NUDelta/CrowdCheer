//
//  DashboardViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 8/24/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import Parse

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var targetRunnerPic: UIImageView!
    @IBOutlet weak var targetRunnerName: UILabel!
    @IBOutlet weak var targetRunnerPace: UILabel!
    @IBOutlet weak var targetRunnerTime: UILabel!
    @IBOutlet weak var targetRunnerDistance: UILabel!
    @IBOutlet weak var targetRunnerLoading: UILabel!
    @IBOutlet weak var targetRunnerETA: UILabel!
    @IBOutlet weak var targetRunnerTimeToCheer: UILabel!
    @IBOutlet weak var targetRunnerTrack: UIButton!
    
    @IBOutlet weak var general1RunnerPic: UIImageView!
    @IBOutlet weak var general1RunnerName: UILabel!
    @IBOutlet weak var general1RunnerTrack: UIButton!
    
    @IBOutlet weak var general2RunnerPic: UIImageView!
    @IBOutlet weak var general2RunnerName: UILabel!
    @IBOutlet weak var general2RunnerTrack: UIButton!
    
    @IBOutlet weak var general3RunnerPic: UIImageView!
    @IBOutlet weak var general3RunnerName: UILabel!
    @IBOutlet weak var general3RunnerTrack: UIButton!

    
    
    
    var runner: PFUser = PFUser()
    var runnerPic: UIImage = UIImage()
    var runnerName: String = ""
    var runnerBib: String = ""
    var runnerLastLoc = CLLocationCoordinate2D()
    
    var userMonitorTimer: NSTimer = NSTimer()
    var nearbyRunnersTimer: NSTimer = NSTimer()
    var areRunnersNearby: Bool = Bool()
    var interval: Int = Int()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var contextPrimer: ContextPrimer = ContextPrimer()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        targetRunnerETA.hidden = true
        targetRunnerTimeToCheer.hidden = true
        
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        areRunnersNearby = false
        interval = 30
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        updateNearbyRunners()
        
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
    }

    override func viewWillDisappear(animated: Bool) {
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        
    }
    
    func monitorUser() {
        
        //start spectator tracker
        spectatorMonitor.monitorUserLocation()
        spectatorMonitor.updateUserLocation()
        spectatorMonitor.updateUserPath(interval)
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState)")
            
            spectatorMonitor.enableBackgroundLoc()
        }
    }
    
    func updateNearbyRunners() {
        //every x seconds, update array of nearby runners and display those runners
        
        var runnerCount = 0
        var targetRunnerTrackingStatus = self.optimizedRunners.targetRunners
        
        
        
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            
            if ((runnerLocations?.isEmpty) == true) {
                self.areRunnersNearby = false
            }
            else {
                self.areRunnersNearby = true
            }
            
            //R+R* Condition
            self.optimizedRunners.considerAffinity(runnerLocations!) { (affinities) -> Void in
                print("affinities \(affinities)")
                
                for (runner, runnerLoc) in runnerLocations! {
                    
                    let runnerCoord = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                    let dist = runnerCoord.distanceFromLocation(self.optimizedRunners.locationMgr.location!)
                    print(runner.username, dist)
                    
                    for affinity in affinities {
                        
                        var isTargetRunnerNear = false
                        if runner == affinity.0 {
                            //Goal: Show target runners throughout the race
                            if dist > 400 { //if runner is more than 2km away (demo: 400)
                                if affinity.1 == 10 { //if target runner, display runner
                                    //TODO: display target runner
                                    self.getRunnerProfile(runner, runnerType: "target")
                                    self.getTargetRunnerStatus(runner)
                                    targetRunnerTrackingStatus[runner.objectId] = true
                                    runnerCount += 1
                                }
                                else if affinity.1 != 10 { //if general runner, don't add them yet
                                    //do nothing
                                }
                            }
                                
                                //Goal: Show all runners near me, including target runners
                            else if dist > 200 && dist <= 400 { //if runner is between 1-2km away (demo: 200-400)
                                if affinity.1 == 10 { //if target runner, add them to the map
                                    //TODO: display target runner
                                    self.getRunnerProfile(runner, runnerType: "target")
                                    self.getTargetRunnerStatus(runner)
                                    targetRunnerTrackingStatus[runner.objectId] = true
                                    runnerCount += 1
                                }
                                else if affinity.1 != 10 { //if general runner, also add them to the map
                                    //TODO: display general runner
//                                    self.getRunnerProfile(runner, runnerType: "general1")
                                    runnerCount += 1
                                    self.sendLocalNotification_any()
                                }
                            }
                                
                                //Goal: If target runner is close, only show them. If not, then continue to show all runners
                            else if dist <= 200 { //if runner is less than 1km away (demo: 200)
                                if affinity.1 == 10 { //if target runner, add them to the map & notify
                                    //TODO: display target runner
                                    self.getRunnerProfile(runner, runnerType: "target")
                                    self.getTargetRunnerStatus(runner)
                                    targetRunnerTrackingStatus[runner.objectId] = true
                                    runnerCount += 1
                                    let name = runner.valueForKey("name") as! String
                                    self.sendLocalNotification_target(name)
                                    isTargetRunnerNear = true
                                }
                                else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                    if !isTargetRunnerNear {
                                        //TODO: display general runner
//                                        self.getRunnerProfile(runner, runnerType: "general1")
                                        runnerCount += 1
                                    }
                                }
                            }
                        }
                    }
                }
                //if target runners are not showing up, notify target runners to start tracking
                self.notifyTargetRunners(targetRunnerTrackingStatus)
                
                //update general runners you can cheer for
                
                self.nearbyRunners.saveRunnerCount(runnerCount)
            }
            
            //            //TESTING//
            //            self.optimizedRunners.considerConvenience(runnerLocations!) { (conveniences) -> Void in
            //                print("conveniences \(conveniences)")
            //            }
            //
            //            self.optimizedRunners.considerNeed(runnerLocations!) { (needs) -> Void in
            //                print("needs \(needs)")
            //            }
        }
        
        
    }
    
    
    func getRunnerProfile(runner: PFUser, runnerType: String) {
        
        if runnerType == "target" {
            
            let name = (runner.valueForKey("name"))!
            let userImageFile = runner["profilePic"] as? PFFile
            userImageFile!.getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        let image = UIImage(data:imageData)
                        self.targetRunnerPic.image = image!
                    }
                }
            }
            targetRunnerName.text = (name as? String)!
        }
    }
    
    func getTargetRunnerStatus(runner: PFUser) {
        
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in
            
            self.runnerLastLoc = runnerLoc
        }
        
        if contextPrimer.pace == "" {
            self.targetRunnerPace.hidden = true
            self.targetRunnerDistance.hidden = true
            self.targetRunnerTime.hidden = true
        }
        
        else {
            self.targetRunnerLoading.hidden = true
            self.targetRunnerPace.text = (contextPrimer.pace as String)
            self.targetRunnerDistance.text = String(format: " %.02f", contextPrimer.distance) + "mi"
            self.targetRunnerTime.text = (contextPrimer.duration as String) + "s"
            self.targetRunnerETA.text = "runner ETA here"
            self.targetRunnerPace.hidden = false
            self.targetRunnerDistance.hidden = false
            self.targetRunnerTime.hidden = false
            self.targetRunnerETA.hidden = false
        }
    }
    
    func sendLocalNotification_any() {
        if areRunnersNearby == true {
            
            if UIApplication.sharedApplication().applicationState == .Background {
                let localNotification = UILocalNotification()
                localNotification.alertBody = "Cheer for runners near you!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                
                UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
            }
        }
            
        else {
            print("local notification: no runners nearby")
        }
    }
    
    func sendLocalNotification_target(name: String) {
        
        if UIApplication.sharedApplication().applicationState == .Background {
            
            let localNotification = UILocalNotification()
            localNotification.alertBody =  name + " is near you, get ready to cheer!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
            
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        }
            
        else if UIApplication.sharedApplication().applicationState == .Active {
            
            let alertTitle = name + " is nearby!"
            let alertController = UIAlertController(title: alertTitle, message: "Get ready to cheer!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func notifyTargetRunners(targetRunnersStatus: [String: Bool]) {
        
        var runner: PFUser
        
        for targetRunner in targetRunnersStatus {
            if targetRunner.1 == false {
                runner = PFQuery.getUserObjectWithId(targetRunner.0)
                let name = runner.valueForKey("name") as! String
                
                if UIApplication.sharedApplication().applicationState == .Background {
                    
                    let localNotification = UILocalNotification()
                    localNotification.alertBody =  name + "'s phone isn't active! Call or text to remind them to use the app!"
                    localNotification.soundName = UILocalNotificationDefaultSoundName
                    localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                    
                    UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
                }
                    
                else if UIApplication.sharedApplication().applicationState == .Active {
                    
                    let alertTitle = name + "'s phone isn't active!"
                    let alertController = UIAlertController(title: alertTitle, message: "You won't see your runners if their phones aren't active. Call or text them to remind them to use the app!", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "Call", style: UIAlertActionStyle.Default, handler: openPhone))
                    alertController.addAction(UIAlertAction(title: "Text", style: UIAlertActionStyle.Default, handler: openMessages))
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                
            }
        }
    }

    func openPhone(alert: UIAlertAction!) {
        UIApplication.sharedApplication().openURL(NSURL(string:"tel:1")!)
    }
    
    func openMessages(alert: UIAlertAction!) {
        UIApplication.sharedApplication().openURL(NSURL(string:"sms:")!)
    }

}