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
    @IBOutlet weak var targetRunner5More: UILabel!
    @IBOutlet weak var targetRunner5Less: UILabel!
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
    var nearbyGeneralRunnersTimer: NSTimer = NSTimer()
    var areRunnersNearby: Bool = Bool()
    var areTargetRunnersNearby: Bool = Bool()
    var targetRunnerNameText: String = ""
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
        targetRunner5More.hidden = true
        targetRunner5Less.hidden = true
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
        areTargetRunnersNearby = false
        areRunnersNearby = false
        interval = 30
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        
        updateNearbyRunners()
        
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyGeneralRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(60*5, target: self, selector: #selector(DashboardViewController.sendLocalNotification_any), userInfo: nil, repeats: true)
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: false)
        nearbyTargetRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.sendLocalNotification_target), userInfo: nil, repeats: true)
        
    }

    override func viewWillDisappear(animated: Bool) {
        print("viewWillDisappear")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        nearbyGeneralRunnersTimer.invalidate()
        nearbyTargetRunnersTimer.invalidate()
        
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
                
                self.targetRunnerLoading.hidden = false
                self.targetRunnerETA.hidden = true
                self.targetRunner5More.hidden = true
                self.targetRunner5Less.hidden = true
                self.targetRunnerTimeToCheer.hidden = true
                
                self.targetRunnerPic.hidden = true
                self.targetRunnerName.hidden = true
                self.targetRunnerTime.hidden = true
                self.targetRunnerPace.hidden = true
                self.targetRunnerDistance.hidden = true
                self.targetRunnerTrack.hidden = true
                
                self.general1RunnerPic.hidden = true
                self.general1RunnerName.hidden = true
                self.general1RunnerTrack.hidden = true
                
                self.general2RunnerPic.hidden = true
                self.general2RunnerName.hidden = true
                self.general2RunnerTrack.hidden = true
                
                self.general3RunnerPic.hidden = true
                self.general3RunnerName.hidden = true
                self.general3RunnerTrack.hidden = true
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
                        
                        //Goal: Show target runners throughout the race
                        if dist > 400 { //if runner is more than 2km away (demo: 400)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunnerLoading.hidden = true
                                self.targetRunnerETA.hidden = false
                                self.targetRunnerETA.text = (name) + " is more than 10 min away"
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId] = true
                                runnerCount += 1
                            }
                            else if affinity.1 != 10 { //if general runner, don't add them yet
                                //do nothing
                            }
                        }
                            
                        //Goal: Show all runners near me, including target runners
                        else if dist > 300 && dist <= 400 { //if runner is between 1-2km away (demo: 300-400)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunnerETA.hidden = true
                                self.targetRunner5More.hidden = false
                                self.targetRunner5More.text = (name) + " is more than 5 min away"
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId] = true
                                runnerCount += 1
                            }
                            else if affinity.1 != 10 { //if general runner, display runner
                                self.getRunnerProfile(runner, runnerType: "general")
                                runnerCount += 1
                                self.areRunnersNearby = true
                            }
                        }
                        
                        //Goal: if target runner is close, disable general runners & only show targets.
                        else if dist > 250 && dist <= 300 { //if runner is between 500m - 1k away (demo: 250-300)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunner5More.hidden = true
                                self.targetRunner5Less.hidden = false
                                self.targetRunner5Less.text = (name) + " is less than 5 min away"
                                self.disableGeneralRunners()
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId] = true
                                runnerCount += 1
                            
                                isTargetRunnerNear = true
                            }
                            else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                if !isTargetRunnerNear {
                                    self.getRunnerProfile(runner, runnerType: "general")
                                    runnerCount += 1
                                    self.areRunnersNearby = true
                                }
                            }
                        }
                            
                        //Goal: If target runner is close, only show them. If not, then continue to show all runners
                        else if dist <= 250 { //if runner is less than 500m away (demo: 250)
                            if affinity.1 == 10 { //if target runner, display runner & notify
                                self.targetRunner5Less.hidden = true
                                self.targetRunnerTimeToCheer.text = (name) + "is nearby!"
                                self.targetRunnerTimeToCheer.hidden = false
                                self.targetRunnerTrack.hidden = false
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId] = true
                                runnerCount += 1
                                
                                self.areTargetRunnersNearby = true
                                self.targetRunnerNameText = name
                                isTargetRunnerNear = true
                            }
                            else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                if !isTargetRunnerNear {
                                    self.getRunnerProfile(runner, runnerType: "general")
                                    runnerCount += 1
                                    self.areRunnersNearby = true
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
            self.targetRunnerETA.text = ((name) as! String) + " is more than 10 min away"

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
                
                
                let runner1 = PFQuery.getUserObjectWithId(generalRunners[0])
                general1Runner = runner1
                let name = (runner1.valueForKey("name"))!
                let userImageFile = runner1["profilePic"] as? PFFile
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
                
                //update general 1
                let runner1 = PFQuery.getUserObjectWithId(generalRunners[0])
                general1Runner = runner1
                let name = (runner1.valueForKey("name"))!
                let userImageFile = runner1["profilePic"] as? PFFile
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
                
                //update general 2
                let runner2 = PFQuery.getUserObjectWithId(generalRunners[1])
                general2Runner = runner2
                let name2 = (runner2.valueForKey("name"))!
                let userImageFile2 = runner2["profilePic"] as? PFFile
                userImageFile2!.getDataInBackgroundWithBlock {
                    (imageData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            let image = UIImage(data:imageData)
                            self.general2RunnerPic.image = image!
                        }
                    }
                }
                general2RunnerName.text = (name2 as? String)!
                general2RunnerPic.hidden = false
                general2RunnerName.hidden = false
                general2RunnerTrack.hidden = false
            }
                
            else if generalRunners.count > 2 {
                
                //update general 1
                let runner1 = PFQuery.getUserObjectWithId(generalRunners[0])
                general1Runner = runner1
                let name = (runner1.valueForKey("name"))!
                let userImageFile = runner1["profilePic"] as? PFFile
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
                
                //update general 2
                let runner2 = PFQuery.getUserObjectWithId(generalRunners[1])
                general2Runner = runner2
                let name2 = (runner2.valueForKey("name"))!
                let userImageFile2 = runner2["profilePic"] as? PFFile
                userImageFile2!.getDataInBackgroundWithBlock {
                    (imageData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            let image = UIImage(data:imageData)
                            self.general2RunnerPic.image = image!
                        }
                    }
                }
                general2RunnerName.text = (name2 as? String)!
                general2RunnerPic.hidden = false
                general2RunnerName.hidden = false
                general2RunnerTrack.hidden = false
                
                //update general 3
                let runner3 = PFQuery.getUserObjectWithId(generalRunners[2])
                general3Runner = runner3
                let name3 = (runner3.valueForKey("name"))!
                let userImageFile3 = runner3["profilePic"] as? PFFile
                userImageFile3!.getDataInBackgroundWithBlock {
                    (imageData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            let image = UIImage(data:imageData)
                            self.general3RunnerPic.image = image!
                        }
                    }
                }
                general3RunnerName.text = (name3 as? String)!
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
    
    func disableGeneralRunners() {
        general1RunnerTrack.enabled = false
        general2RunnerTrack.enabled = false
        general3RunnerTrack.enabled = false
        general1RunnerTrack.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        general2RunnerTrack.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        general3RunnerTrack.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
    }
    
    func sendLocalNotification_target() {
        
        let name = targetRunnerNameText
        
        if areTargetRunnersNearby == true {
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
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: dismissCheerTarget))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
            
        else {
            print("local notification: no target runners nearby")
        }
    }
    
    func dismissCheerTarget(alert: UIAlertAction!) {
        
        nearbyTargetRunnersTimer.invalidate()
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
        nearbyTargetRunnersTimer.invalidate()
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