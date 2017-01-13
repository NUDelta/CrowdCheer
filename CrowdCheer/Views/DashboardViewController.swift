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
    var runnerProfiles = [String:[String:AnyObject]]()
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
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: false)
        
        nearbyGeneralRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(60*5, target: self, selector: #selector(DashboardViewController.sendLocalNotification_any), userInfo: nil, repeats: true)
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
                
                //update profiles of existing runners
                self.updateRunnerProfiles(runnerLocations!)
                
                //sort out target & general runners
                self.considerRunnerAffinity(self.runnerLocations)
            }
        }
    }
    
    func updateRunnerProfiles(runnerLocations: [PFUser: PFGeoPoint]) {
        
        for (runner, runnerLoc) in runnerLocations {
            
            print("is \(runner.username) missing \(runnerProfiles[runner.objectId!])")
            if runnerProfiles[runner.objectId!] == nil {
                nearbyRunners.getRunnerProfile(runner.objectId!) { (runnerProfile) -> Void in
                    
                    self.runnerProfiles[runner.objectId!] = runnerProfile
                    print("runner profile did not exist, added  \(runner.username)")
                    print(self.runnerProfiles)
                }
            }
            else {
                print("runner profile exists, will not query")
            }
        }
    }
    
    func getRunnerImage(runnerObjID: String, runnerProfiles: [String:[String:AnyObject]]) -> UIImage {
        let runnerProfile = runnerProfiles[runnerObjID]
        let imagePath = runnerProfile!["profilePicPath"] as! String
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(imagePath){
            let image = UIImage(contentsOfFile: imagePath)
            return image!
        }
        else{
            print("No Image, using generic")
            let image = UIImage(named: "profile.png")
            return image!
        }
    }
    
    func getRunnerName(runnerObjID: String, runnerProfiles: [String:[String:AnyObject]]) -> String {
        let runnerProfile = runnerProfiles[runnerObjID]
        print(runnerProfiles)
        let name = runnerProfile!["name"] as! String //NOTE: crashes here, just before it calls getRunnerProfile in ln 419 (x1) & 355 (x5), and before that runs a query in Match ln 402 (x6)
        return name
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
                        if dist > 2000 { //if runner is more than 2km away (demo: 400)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunnerLoading.hidden = true
                                self.targetRunnerETA.hidden = false
                                self.targetRunnerETA.text = (name) + " is more than 10 min away"
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId!] = true
                                runnerCount += 1
                            }
                            else if affinity.1 != 10 { //if general runner, don't add them yet
                                //do nothing
                            }
                        }
                            
                        //Goal: Show all runners near me, including target runners
                        else if dist > 1000 && dist <= 2000 { //if runner is between 1-2km away (demo: 300-400)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunnerETA.hidden = true
                                self.targetRunnerLoading.hidden = true
                                self.targetRunner5More.hidden = false
                                self.targetRunner5More.text = (name) + " is more than 5 min away"
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId!] = true
                                runnerCount += 1
                            }
                            else if affinity.1 != 10 { //if general runner, display runner
                                self.getRunnerProfile(runner, runnerType: "general")
                                runnerCount += 1
                                self.areRunnersNearby = true
                            }
                        }
                        
                        //Goal: if target runner is close, disable general runners & only show targets.
                        else if dist > 500 && dist <= 1000 { //if runner is between 500m - 1k away (demo: 250-300)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunner5More.hidden = true
                                self.targetRunnerLoading.hidden = true
                                self.targetRunner5Less.hidden = false
                                self.targetRunner5Less.text = (name) + " is less than 5 min away"
                                self.disableGeneralRunners()
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId!] = true
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
                        else if dist <= 500 { //if runner is less than 500m away (demo: 250)
                            if affinity.1 == 10 { //if target runner, display runner & notify
                                
                                self.nearbyRunnersTimer.invalidate()
                                self.nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
                                
                                self.targetRunner5Less.hidden = true
                                self.targetRunnerLoading.hidden = true
                                self.targetRunnerTimeToCheer.text = (name) + " is nearby!"
                                self.targetRunnerTimeToCheer.hidden = false
                                self.targetRunnerTrack.hidden = false
                                self.getRunnerProfile(runner, runnerType: "target")
                                self.targetRunnerTrackingStatus[runner.objectId!] = true
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
            self.targetRunnerTrackingStatus = self.optimizedRunners.targetRunners
            print("targetRunnerTrackingStatus inside considerAffinity: \(self.targetRunnerTrackingStatus)")
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
        
        if !self.runnerProfiles.isEmpty {
            
            let runnerName = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
            let runnerImage = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
            
            if runnerType == "target" {
                
                targetRunner = runner
                self.getTargetRunnerStatus(targetRunner)
                self.targetRunnerPic.image = runnerImage
                
                targetRunnerName.text = runnerName
                targetRunnerPic.hidden = false
                targetRunnerName.hidden = false
                self.targetRunnerETA.text = (runnerName) + " is more than 10 min away"
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
                    let runner1ObjID = generalRunners[0]
                    do {
                        general1Runner = try PFQuery.getUserObjectWithId(generalRunners[0])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name = getRunnerName(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    self.general1RunnerPic.image = getRunnerImage(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general1RunnerName.text = name
                    general1RunnerPic.hidden = false
                    general1RunnerName.hidden = false
                    general1RunnerTrack.hidden = false
                }
                    
                else if generalRunners.count == 2 {
                    
                    //update general 1
                    let runner1ObjID = generalRunners[0]
                    do {
                        general1Runner = try PFQuery.getUserObjectWithId(generalRunners[0]) //NOTE: crashes here, just before it runs a query in Match ln 402
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name1 = getRunnerName(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    self.general1RunnerPic.image = getRunnerImage(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general1RunnerName.text = name1
                    general1RunnerPic.hidden = false
                    general1RunnerName.hidden = false
                    general1RunnerTrack.hidden = false
                    
                    //update general 2
                    let runner2ObjID = generalRunners[1]
                    do {
                        general2Runner = try PFQuery.getUserObjectWithId(generalRunners[1]) //NOTE: crashes here, just before it runs a query in Match ln 402 (x2)
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name2 = getRunnerName(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    self.general2RunnerPic.image = getRunnerImage(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general2RunnerName.text = name2
                    general2RunnerPic.hidden = false
                    general2RunnerName.hidden = false
                    general2RunnerTrack.hidden = false
                }
                    
                else if generalRunners.count > 2 {
                    
                    //update general 1
                    let runner1ObjID = generalRunners[0]
                    do {
                        general1Runner = try PFQuery.getUserObjectWithId(generalRunners[0])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name1 = getRunnerName(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    self.general1RunnerPic.image = getRunnerImage(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general1RunnerName.text = name1
                    general1RunnerPic.hidden = false
                    general1RunnerName.hidden = false
                    general1RunnerTrack.hidden = false
                    
                    //update general 2
                    let runner2ObjID = generalRunners[1]
                    do {
                        general2Runner = try PFQuery.getUserObjectWithId(generalRunners[1])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name2 = getRunnerName(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    self.general2RunnerPic.image = getRunnerImage(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general2RunnerName.text = name2
                    general2RunnerPic.hidden = false
                    general2RunnerName.hidden = false
                    general2RunnerTrack.hidden = false
                    
                    //update general 3
                    let runner3ObjID = generalRunners[2]
                    do {
                        general3Runner = try PFQuery.getUserObjectWithId(generalRunners[2])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name3 = getRunnerName(runner3ObjID, runnerProfiles: self.runnerProfiles)
                    self.general3RunnerPic.image = getRunnerImage(runner3ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general3RunnerName.text = name3
                    general3RunnerPic.hidden = false
                    general3RunnerName.hidden = false
                    general3RunnerTrack.hidden = false
                }
            }
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
                
                var spectatorInfo = [String: AnyObject]()
                spectatorInfo["spectator"] = PFUser.currentUser()!.objectId
                spectatorInfo["source"] = "generalRunnerNotification"
                spectatorInfo["receivedNotification"] = true
                spectatorInfo["receivedNotificationTimestamp"] = NSDate()
                
                
                localNotification.alertBody = "Cheer for runners near you!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                
                spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber
                localNotification.userInfo = spectatorInfo
                
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
                
                var spectatorInfo = [String: AnyObject]()
                spectatorInfo["spectator"] = PFUser.currentUser()!.objectId
                spectatorInfo["source"] = "targetRunnerNotification"
                spectatorInfo["receivedNotification"] = true
                spectatorInfo["receivedNotificationTimestamp"] = NSDate()
                
                localNotification.alertBody =  name + " is near you, get ready to cheer!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                
                spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber
                localNotification.userInfo = spectatorInfo
                
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
