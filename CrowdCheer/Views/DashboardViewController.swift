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
    var targetRunner: PFUser = PFUser()
    
    @IBOutlet weak var general1RunnerPic: UIImageView!
    @IBOutlet weak var general1RunnerName: UILabel!
    @IBOutlet weak var general1RunnerTrack: UIButton!
    var general1Runner: PFUser = PFUser()
    
    @IBOutlet weak var general2RunnerPic: UIImageView!
    @IBOutlet weak var general2RunnerName: UILabel!
    @IBOutlet weak var general2RunnerTrack: UIButton!
    var general2Runner: PFUser = PFUser()
    
    @IBOutlet weak var general3RunnerPic: UIImageView!
    @IBOutlet weak var general3RunnerName: UILabel!
    @IBOutlet weak var general3RunnerTrack: UIButton!
    var general3Runner: PFUser = PFUser()

    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerLocations = [PFUser: PFGeoPoint]()
    var userMonitorTimer: NSTimer = NSTimer()
    var nearbyRunnersTimer: NSTimer = NSTimer()
    var areRunnersNearby: Bool = Bool()
    var targetRunnerTrackingStatus = [String: Bool]()
    var interval: Int = Int()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var contextPrimer: ContextPrimer = ContextPrimer()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        targetRunnerLoading.hidden = false
        targetRunnerETA.hidden = true
        targetRunnerTimeToCheer.hidden = true
        
        targetRunnerPic.hidden = true
        targetRunnerName.hidden = true
        targetRunnerTime.hidden = true
        targetRunnerPace.hidden = true
        targetRunnerDistance.hidden = true
        targetRunnerTrack.hidden = true
        
        general1RunnerPic.hidden = true
        general1RunnerName.hidden = true
        general1RunnerTrack.hidden = true
        
        general2RunnerPic.hidden = true
        general2RunnerName.hidden = true
        general2RunnerTrack.hidden = true
        
        general3RunnerPic.hidden = true
        general3RunnerName.hidden = true
        general3RunnerTrack.hidden = true
        
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
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: false)
        
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
        //every x seconds, monitor target runners, find nearby runners and display those runners
    
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            
            if ((runnerLocations?.isEmpty) == true) {
                self.areRunnersNearby = false
            }
            else {
                self.areRunnersNearby = true
                self.runnerLocations = runnerLocations!
                self.considerRunnerAffinity(self.runnerLocations)
            }
        }
        targetRunnerTrackingStatus = self.optimizedRunners.targetRunners
        print("targetRunnerTrackingStatus: \(targetRunnerTrackingStatus)")
    }
    
    func considerRunnerAffinity(runnerLocations: [PFUser: PFGeoPoint]) {
        //R+R* Condition
        var runnerCount = 0
        
        self.optimizedRunners.considerAffinity(runnerLocations) { (affinities) -> Void in
            print("affinities \(affinities)")
            
            for (runner, runnerLoc) in runnerLocations {
                
                let runnerCoord = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                let dist = runnerCoord.distanceFromLocation(self.optimizedRunners.locationMgr.location!)
                print(runner.username, dist)
                
                for affinity in affinities {
                    
                    var isTargetRunnerNear = false
                    if runner == affinity.0 {
                        let name = runner.valueForKey("name") as! String
                        self.targetRunnerLoading.hidden = true
                        self.targetRunnerETA.hidden = false
                        
                        //Goal: Show target runners throughout the race
                        if dist > 400 { //if runner is more than 2km away (demo: 400)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunnerETA.text = (name) + " is more than 10 min away"
                                self.getRunnerProfile(runner, runnerType: "target")
//                                self.getTargetRunnerStatus(runner)
                                self.targetRunnerTrackingStatus[runner.objectId] = true
                                runnerCount += 1
                            }
                            else if affinity.1 != 10 { //if general runner, don't add them yet
                                //do nothing
                            }
                        }
                            
                            //Goal: Show all runners near me, including target runners
                        else if dist > 200 && dist <= 400 { //if runner is between 500m-2km away (demo: 200-400)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunnerETA.text = (name) + " is more than 5 min away"
                                self.getRunnerProfile(runner, runnerType: "target")
//                                self.getTargetRunnerStatus(runner)
                                self.targetRunnerTrackingStatus[runner.objectId] = true
                                runnerCount += 1
                            }
                            else if affinity.1 != 10 { //if general runner, display runner
                                self.getRunnerProfile(runner, runnerType: "general")
                                runnerCount += 1
                                self.sendLocalNotification_any()
                            }
                        }
                            
                            //Goal: If target runner is close, only show them. If not, then continue to show all runners
                        else if dist <= 200 { //if runner is less than 500m away (demo: 200)
                            if affinity.1 == 10 { //if target runner, display runner & notify
                                self.targetRunnerETA.hidden = true
                                self.targetRunnerTimeToCheer.text = "Time to cheer for " + (name) + "!"
                                self.targetRunnerTimeToCheer.hidden = false
                                self.targetRunnerTrack.hidden = false
                                self.getRunnerProfile(runner, runnerType: "target")
//                                self.getTargetRunnerStatus(runner)
                                self.targetRunnerTrackingStatus[runner.objectId] = true
                                runnerCount += 1
                                self.sendLocalNotification_target(name)
                                isTargetRunnerNear = true
                            }
                            else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                if !isTargetRunnerNear {
                                    self.getRunnerProfile(runner, runnerType: "general")
                                    runnerCount += 1
                                }
                            }
                        }
                    }
                }
            }
            //if target runners are not showing up, notify target runners to start tracking
            self.notifyTargetRunners(self.targetRunnerTrackingStatus)
            self.nearbyRunners.saveRunnerCount(runnerCount)
        }
    }
    
//    //TESTING//
//    self.optimizedRunners.considerConvenience(runnerLocations!) { (conveniences) -> Void in
//    print("conveniences \(conveniences)")
//    }
//    
//    self.optimizedRunners.considerNeed(runnerLocations!) { (needs) -> Void in
//    print("needs \(needs)")
//    }
    
    func getRunnerProfile(runner: PFUser, runnerType: String) {
        
        if runnerType == "target" {
            
            targetRunner = runner
            self.getTargetRunnerStatus(targetRunner)
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
            targetRunnerPic.hidden = false
            targetRunnerName.hidden = false

        }
        
        else if runnerType == "general" {
            
            let generalRunners = self.optimizedRunners.generalRunners
            print("generalRunners in dashboardVC: \(generalRunners)")
            if generalRunners.count == 0 {
                
                //hide all labels
                general1RunnerPic.hidden = true
                general1RunnerName.hidden = true
                general1RunnerTrack.hidden = true
                
                general2RunnerPic.hidden = true
                general2RunnerName.hidden = true
                general2RunnerTrack.hidden = true
                
                general3RunnerPic.hidden = true
                general3RunnerName.hidden = true
                general3RunnerTrack.hidden = true
                
            }
            else if generalRunners.count == 1 {
                //update general 1
                
                general1Runner = runner
                
//                let runner = PFQuery.getUserObjectWithId(generalRunners[0])
                let name = (runner.valueForKey("name"))!
                let userImageFile = runner["profilePic"] as? PFFile
                userImageFile!.getDataInBackgroundWithBlock {
                    (imageData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            let image = UIImage(data:imageData)
                            self.general1RunnerPic.image = image!
                        }
                    }
                }
                general1RunnerName.text = (name as? String)!
                general1RunnerPic.hidden = false
                general1RunnerName.hidden = false
                general1RunnerTrack.hidden = false
            }
            
            else if generalRunners.count == 2 {
                //update general 2
                
                general2Runner = runner
//                let runner = generalRunners[1]
                let name = (runner.valueForKey("name"))!
                let userImageFile = runner["profilePic"] as? PFFile
                userImageFile!.getDataInBackgroundWithBlock {
                    (imageData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            let image = UIImage(data:imageData)
                            self.general2RunnerPic.image = image!
                        }
                    }
                }
                general2RunnerName.text = (name as? String)!
                general2RunnerPic.hidden = false
                general2RunnerName.hidden = false
                general2RunnerTrack.hidden = false
            }
                
            else if generalRunners.count > 2 {
                //update general 3
                
                general3Runner = runner
//                let runner = generalRunners[2]
                let name = (runner.valueForKey("name"))!
                let userImageFile = runner["profilePic"] as? PFFile
                userImageFile!.getDataInBackgroundWithBlock {
                    (imageData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            let image = UIImage(data:imageData)
                            self.general3RunnerPic.image = image!
                        }
                    }
                }
                general3RunnerName.text = (name as? String)!
                general3RunnerPic.hidden = false
                general3RunnerName.hidden = false
                general3RunnerTrack.hidden = false
            }
        }
    }
    
    func getTargetRunnerStatus(runner: PFUser) {
        
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in
            
            self.runnerLastLoc = runnerLoc
        }
        
        if contextPrimer.pace == "" {
            let name = runner.valueForKey("name") as! String
            self.targetRunnerPace.hidden = false
            self.targetRunnerPace.text = "Loading stats..."
            self.targetRunnerDistance.hidden = true
            self.targetRunnerTime.hidden = true
        }
        
        else {
            self.targetRunnerPace.text = (contextPrimer.pace as String)
            self.targetRunnerDistance.text = String(format: " %.02f", contextPrimer.distance) + "mi"
            self.targetRunnerTime.text = (contextPrimer.duration as String) + "s"
            
            self.targetRunnerPace.hidden = false
            self.targetRunnerDistance.hidden = false
            self.targetRunnerTime.hidden = false
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
    
    @IBAction func targetTrack(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(targetRunner) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegueWithIdentifier("trackRunner", sender: nil)
    }
    
    @IBAction func general1Track(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general1Runner) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegueWithIdentifier("trackRunner", sender: nil)
    }
    
    @IBAction func general2Track(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general2Runner) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegueWithIdentifier("trackRunner", sender: nil)
    }
    
    @IBAction func general3Track(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general3Runner) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegueWithIdentifier("trackRunner", sender: nil)
    }





}