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
    var userMonitorTimer: Timer = Timer()
    var nearbyRunnersTimer: Timer = Timer()
    var nearbyGeneralRunnersTimer: Timer = Timer()
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
        
        targetRunnerLoading.isHidden = false
        targetRunnerETA.isHidden = true
        targetRunner5More.isHidden = true
        targetRunner5Less.isHidden = true
        targetRunnerTimeToCheer.isHidden = true
        
        targetRunnerPic.isHidden = true
        targetRunnerName.isHidden = true
        targetRunnerTime.isHidden = true
        targetRunnerPace.isHidden = true
        targetRunnerDistance.isHidden = true
        targetRunnerTrack.isHidden = true
        
        general1RunnerPic.isHidden = true
        general1RunnerName.isHidden = true
        general1RunnerTrack.isHidden = true
        
        general2RunnerPic.isHidden = true
        general2RunnerName.isHidden = true
        general2RunnerTrack.isHidden = true
        
        general3RunnerPic.isHidden = true
        general3RunnerName.isHidden = true
        general3RunnerTrack.isHidden = true
        
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        areTargetRunnersNearby = false
        areRunnersNearby = false
        interval = 30
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        
        updateNearbyRunners()
        
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: false)
        
        nearbyGeneralRunnersTimer = Timer.scheduledTimer(timeInterval: 60*5, target: self, selector: #selector(DashboardViewController.sendLocalNotification_any), userInfo: nil, repeats: true)
        nearbyTargetRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.sendLocalNotification_target), userInfo: nil, repeats: true)
        
    }

    override func viewWillDisappear(_ animated: Bool) {
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
        
        if UIApplication.shared.applicationState == .background {
            print("app status: \(UIApplication.shared.applicationState)")
            
            spectatorMonitor.enableBackgroundLoc()
        }
    }
    
    func updateNearbyRunners() {
        //every x seconds, monitor target runners, find nearby runners and display those runners
    
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            
            if ((runnerLocations?.isEmpty) == true) {
                self.areRunnersNearby = false
                
                self.targetRunnerLoading.isHidden = false
                self.targetRunnerETA.isHidden = true
                self.targetRunner5More.isHidden = true
                self.targetRunner5Less.isHidden = true
                self.targetRunnerTimeToCheer.isHidden = true
                
                self.targetRunnerPic.isHidden = true
                self.targetRunnerName.isHidden = true
                self.targetRunnerTime.isHidden = true
                self.targetRunnerPace.isHidden = true
                self.targetRunnerDistance.isHidden = true
                self.targetRunnerTrack.isHidden = true
                
                self.general1RunnerPic.isHidden = true
                self.general1RunnerName.isHidden = true
                self.general1RunnerTrack.isHidden = true
                
                self.general2RunnerPic.isHidden = true
                self.general2RunnerName.isHidden = true
                self.general2RunnerTrack.isHidden = true
                
                self.general3RunnerPic.isHidden = true
                self.general3RunnerName.isHidden = true
                self.general3RunnerTrack.isHidden = true
            }
            else {
                self.runnerLocations = runnerLocations!
                
                //update profiles of existing runners
                self.updateRunnerProfiles(runnerLocations!)
                
                //sort out target & general runners
                self.considerRunnerAffinity(self.runnerLocations)
            }
        }
    }
    
    func updateRunnerProfiles(_ runnerLocations: [PFUser: PFGeoPoint]) {
        
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
    
    func getRunnerImage(_ runnerObjID: String, runnerProfiles: [String:[String:AnyObject]]) -> UIImage {
        var image: UIImage = UIImage(named: "profileDefault.png")!
        if runnerProfiles[runnerObjID] != nil {
            let runnerProfile = runnerProfiles[runnerObjID]
            let imagePath = runnerProfile!["profilePicPath"] as! String
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: imagePath){
                image = UIImage(contentsOfFile: imagePath)!
            }
        }
        else {
            print("No Image, using generic")
            image = UIImage(named: "profileDefault.png")!
        }
        return image
    }
    
    func getRunnerName(_ runnerObjID: String, runnerProfiles: [String:[String:AnyObject]]) -> String {
        
        if runnerProfiles[runnerObjID] != nil {
            let runnerProfile = runnerProfiles[runnerObjID]
            print(runnerProfiles)
            let name = runnerProfile!["name"] as! String //NOTE: crashes here, just before it calls getRunnerProfile in ln 419 (x1) & 355 (x5), and before that runs a query in Match ln 402 (x6) - in line 220, the dictionary doesn't have that runner in it yet, so it can't get the profile info of the runner
            return name
        }
        else {
            print("No name found, using generic")
            let name = ""
            return name
        }
        
    }
    
    func considerRunnerAffinity(_ runnerLocations: [PFUser: PFGeoPoint]) {
        //R+R* Condition
        var runnerCount = 0
        
        self.optimizedRunners.considerAffinity(runnerLocations) { (affinities) -> Void in
            print("affinities \(affinities)")
            
            for (runner, runnerLoc) in runnerLocations {
                
                let runnerCoord = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                let dist = runnerCoord.distance(from: self.optimizedRunners.locationMgr.location!)
                print(runner.username, dist)
                
                for affinity in affinities {
                    
                    var isTargetRunnerNear = false
                    if runner == affinity.0 {
                        let name = runner.value(forKey: "name") as! String
                        
                        //Goal: Show target runners throughout the race
                        if dist > 2000 { //if runner is more than 2km away (demo: 400)
                            if affinity.1 == 10 { //if target runner, display runner
                                self.targetRunnerLoading.isHidden = true
                                self.targetRunnerETA.isHidden = false
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
                                self.targetRunnerETA.isHidden = true
                                self.targetRunnerLoading.isHidden = true
                                self.targetRunner5More.isHidden = false
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
                                self.targetRunner5More.isHidden = true
                                self.targetRunnerLoading.isHidden = true
                                self.targetRunner5Less.isHidden = false
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
                                self.nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
                                
                                self.targetRunner5Less.isHidden = true
                                self.targetRunnerLoading.isHidden = true
                                self.targetRunnerTimeToCheer.text = (name) + " is nearby, support them now!"
                                self.targetRunnerTimeToCheer.isHidden = false
                                self.targetRunnerTrack.isHidden = false
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
    
    
    func getRunnerProfile(_ runner: PFUser, runnerType: String) {
        
        if !self.runnerProfiles.isEmpty {
            
            let runnerName = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
            let runnerImage = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
            
            if runnerType == "target" {
                
                targetRunner = runner
                self.getTargetRunnerStatus(targetRunner)
                self.targetRunnerPic.image = runnerImage
                
                targetRunnerName.text = runnerName
                targetRunnerPic.isHidden = false
                targetRunnerName.isHidden = false
                self.targetRunnerETA.text = (runnerName) + " is more than 10 min away"
            }
                
            else if runnerType == "general" {
                
                let generalRunners = self.optimizedRunners.generalRunners
                print("generalRunners in dashboardVC: \(generalRunners)")
                if generalRunners.count == 0 {
                    
                    //hide all labels
                    general1RunnerPic.isHidden = true
                    general1RunnerName.isHidden = true
                    general1RunnerTrack.isHidden = true
                    
                    general2RunnerPic.isHidden = true
                    general2RunnerName.isHidden = true
                    general2RunnerTrack.isHidden = true
                    
                    general3RunnerPic.isHidden = true
                    general3RunnerName.isHidden = true
                    general3RunnerTrack.isHidden = true
                    
                }
                else if generalRunners.count == 1 {
                    //update general 1
                    let runner1ObjID = generalRunners[0]
                    do {
                        general1Runner = try PFQuery.getUserObject(withId: generalRunners[0])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name = getRunnerName(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    self.general1RunnerPic.image = getRunnerImage(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general1RunnerName.text = name
                    general1RunnerPic.isHidden = false
                    general1RunnerName.isHidden = false
                    general1RunnerTrack.isHidden = false
                }
                    
                else if generalRunners.count == 2 {
                    
                    //update general 1
                    let runner1ObjID = generalRunners[0]
                    do {
                        general1Runner = try PFQuery.getUserObject(withId: generalRunners[0]) //NOTE: crashes here, just before it runs a query in Match ln 402
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name1 = getRunnerName(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    self.general1RunnerPic.image = getRunnerImage(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general1RunnerName.text = name1
                    general1RunnerPic.isHidden = false
                    general1RunnerName.isHidden = false
                    general1RunnerTrack.isHidden = false
                    
                    //update general 2
                    let runner2ObjID = generalRunners[1]
                    do {
                        general2Runner = try PFQuery.getUserObject(withId: generalRunners[1]) //NOTE: crashes here, just before it runs a query in Match ln 402 (x2)
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name2 = getRunnerName(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    self.general2RunnerPic.image = getRunnerImage(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general2RunnerName.text = name2
                    general2RunnerPic.isHidden = false
                    general2RunnerName.isHidden = false
                    general2RunnerTrack.isHidden = false
                }
                    
                else if generalRunners.count > 2 {
                    
                    //update general 1
                    let runner1ObjID = generalRunners[0]
                    do {
                        general1Runner = try PFQuery.getUserObject(withId: generalRunners[0])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name1 = getRunnerName(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    self.general1RunnerPic.image = getRunnerImage(runner1ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general1RunnerName.text = name1
                    general1RunnerPic.isHidden = false
                    general1RunnerName.isHidden = false
                    general1RunnerTrack.isHidden = false
                    
                    //update general 2
                    let runner2ObjID = generalRunners[1]
                    do {
                        general2Runner = try PFQuery.getUserObject(withId: generalRunners[1])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name2 = getRunnerName(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    self.general2RunnerPic.image = getRunnerImage(runner2ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general2RunnerName.text = name2
                    general2RunnerPic.isHidden = false
                    general2RunnerName.isHidden = false
                    general2RunnerTrack.isHidden = false
                    
                    //update general 3
                    let runner3ObjID = generalRunners[2]
                    do {
                        general3Runner = try PFQuery.getUserObject(withId: generalRunners[2])
                    }
                    catch {
                        print("ERROR: unable to get runner")
                    }
                    let name3 = getRunnerName(runner3ObjID, runnerProfiles: self.runnerProfiles)
                    self.general3RunnerPic.image = getRunnerImage(runner3ObjID, runnerProfiles: self.runnerProfiles)
                    
                    general3RunnerName.text = name3
                    general3RunnerPic.isHidden = false
                    general3RunnerName.isHidden = false
                    general3RunnerTrack.isHidden = false
                }
            }
        }
    }
    
    func getTargetRunnerStatus(_ runner: PFUser) {
        
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in
            
            self.runnerLastLoc = runnerLoc
        }
        
        if contextPrimer.pace == "" {
            self.targetRunnerPace.isHidden = true
            self.targetRunnerDistance.isHidden = true
            self.targetRunnerTime.isHidden = true
        }
        
        else {
            self.targetRunnerPace.text = (contextPrimer.pace as String)
            self.targetRunnerDistance.text = String(format: " %.02f", contextPrimer.distance) + "mi"
            self.targetRunnerTime.text = (contextPrimer.duration as String) + "s"
            
            self.targetRunnerPace.isHidden = false
            self.targetRunnerDistance.isHidden = false
            self.targetRunnerTime.isHidden = false
        }
    }
    
    func sendLocalNotification_any() {
        if areRunnersNearby == true {
            
            if UIApplication.shared.applicationState == .background {
                let localNotification = UILocalNotification()
                
                var spectatorInfo = [String: AnyObject]()
                spectatorInfo["spectator"] = PFUser.current()!.objectId
                spectatorInfo["source"] = "generalRunnerNotification"
                spectatorInfo["receivedNotification"] = true
                spectatorInfo["receivedNotificationTimestamp"] = Date()
                
                
                localNotification.alertBody = "Cheer for runners near you!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                
                spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber
                localNotification.userInfo = spectatorInfo
                
                UIApplication.shared.presentLocalNotificationNow(localNotification)
            }
        }
            
        else {
            print("local notification: no runners nearby")
        }
    }
    
    func disableGeneralRunners() {
        general1RunnerTrack.isEnabled = false
        general2RunnerTrack.isEnabled = false
        general3RunnerTrack.isEnabled = false
        general1RunnerTrack.setTitleColor(UIColor.gray, for: UIControlState.disabled)
        general2RunnerTrack.setTitleColor(UIColor.gray, for: UIControlState.disabled)
        general3RunnerTrack.setTitleColor(UIColor.gray, for: UIControlState.disabled)
    }
    
    func sendLocalNotification_target() {
        
        let name = targetRunnerNameText
        
        if areTargetRunnersNearby == true {
            if UIApplication.shared.applicationState == .background {
                
                let localNotification = UILocalNotification()
                
                var spectatorInfo = [String: AnyObject]()
                spectatorInfo["spectator"] = PFUser.current()!.objectId
                spectatorInfo["source"] = "targetRunnerNotification"
                spectatorInfo["receivedNotification"] = true
                spectatorInfo["receivedNotificationTimestamp"] = Date()
                
                localNotification.alertBody =  name + " is nearby, get ready to support them!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                
                spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber
                localNotification.userInfo = spectatorInfo
                
                UIApplication.shared.presentLocalNotificationNow(localNotification)
            }
                
            else if UIApplication.shared.applicationState == .active {
                
                let alertTitle = name + " is nearby!"
                let alertController = UIAlertController(title: alertTitle, message: "Get ready to support them!", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: dismissCheerTarget))
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
            
        else {
            print("local notification: no target runners nearby")
        }
    }
    
    func dismissCheerTarget(_ alert: UIAlertAction!) {
        
        nearbyTargetRunnersTimer.invalidate()
    }
    
    @IBAction func targetTrack(_ sender: UIButton) {
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
        performSegue(withIdentifier: "trackRunner", sender: nil)
    }
    
    @IBAction func general1Track(_ sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general1Runner) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegue(withIdentifier: "trackRunner", sender: nil)
    }
    
    @IBAction func general2Track(_ sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general2Runner) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegue(withIdentifier: "trackRunner", sender: nil)
    }
    
    @IBAction func general3Track(_ sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general3Runner) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegue(withIdentifier: "trackRunner", sender: nil)
    }
}
