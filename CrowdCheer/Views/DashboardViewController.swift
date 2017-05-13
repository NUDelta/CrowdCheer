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

class DashboardViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var targetRunnerPic: UIImageView!
    @IBOutlet weak var targetRunnerName: UILabel!
    @IBOutlet weak var targetRunnerETA: UILabel!
    @IBOutlet weak var targetRunnerCheers: UILabel!
    @IBOutlet weak var targetRunnerTrack: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    var targetRunner: PFUser = PFUser()
    
    @IBOutlet weak var general1RunnerPic: UIImageView!
    @IBOutlet weak var general1RunnerName: UILabel!
    @IBOutlet weak var general1RunnerETA: UILabel!
    @IBOutlet weak var general1RunnerCheers: UILabel!
    @IBOutlet weak var general1RunnerTrack: UIButton!
    var general1Runner: PFUser = PFUser()
    
    @IBOutlet weak var general2RunnerPic: UIImageView!
    @IBOutlet weak var general2RunnerName: UILabel!
    @IBOutlet weak var general2RunnerETA: UILabel!
    @IBOutlet weak var general2RunnerCheers: UILabel!
    @IBOutlet weak var general2RunnerTrack: UIButton!
    var general2Runner: PFUser = PFUser()
    
    @IBOutlet weak var general3RunnerPic: UIImageView!
    @IBOutlet weak var general3RunnerName: UILabel!
    @IBOutlet weak var general3RunnerETA: UILabel!
    @IBOutlet weak var general3RunnerCheers: UILabel!
    @IBOutlet weak var general3RunnerTrack: UIButton!
    var general3Runner: PFUser = PFUser()
    
    @IBOutlet weak var idleTimeBanner: UILabel!
    
    @IBOutlet weak var redLabel: UILabel!

    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerLocations = [PFUser: PFGeoPoint]()
    var runnerProfiles = [String:[String:AnyObject]]()
    var runnerCheers = [PFUser: Int]()
    var runnerETAs = [PFUser: Int]()
    var userMonitorTimer: Timer = Timer()
    var nearbyRunnersTimer: Timer = Timer()
    var nearbyGeneralRunnersTimer: Timer = Timer()
    var areRunnersNearby: Bool = Bool()
    var areTargetRunnersNearby: Bool = Bool()
    var targetRunnerNameText: String = ""
    var nearbyTargetRunners = [String: Bool]()
    var interval: Int = Int()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var contextPrimer: ContextPrimer = ContextPrimer()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    
        
        // Flow 1 - Hide all runner information
        
        targetRunnerPic.isHidden = true
        targetRunnerName.isHidden = true
        targetRunnerETA.isHidden = true
        targetRunnerCheers.isHidden = true
        targetRunnerTrack.isHidden = true
        
        general1RunnerPic.isHidden = true
        general1RunnerName.isHidden = true
        general1RunnerETA.isHidden = true
        general1RunnerCheers.isHidden = true
        general1RunnerTrack.isHidden = true
        
        general2RunnerPic.isHidden = true
        general2RunnerName.isHidden = true
        general2RunnerETA.isHidden = true
        general2RunnerCheers.isHidden = true
        general2RunnerTrack.isHidden = true
        
        general3RunnerPic.isHidden = true
        general3RunnerName.isHidden = true
        general3RunnerETA.isHidden = true
        general3RunnerCheers.isHidden = true
        general3RunnerTrack.isHidden = true
        
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        areTargetRunnersNearby = false
        areRunnersNearby = false
        interval = 30
        
        
        //initialize mapview
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        
        
        // Flow 2 - check once for any nearby runners and add them to dash
        
        updateNearbyRunners()
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: false)
        
        // Flow 3 - every interval, log spectator loc and update nearby runners
        
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
        
        // Flow 4 - every interval, notify spectators if 1) R runners are nearby and 2) R* runners are nearby
        
//        nearbyGeneralRunnersTimer = Timer.scheduledTimer(timeInterval: 60*5, target: self, selector: #selector(DashboardViewController.sendLocalNotification_any), userInfo: nil, repeats: true)
        nearbyGeneralRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.sendLocalNotification_any), userInfo: nil, repeats: true)
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
        //find nearby runners and display those runners

        
        // Flow 3.1 - remove R* pins from map and reset nearbyRunners
        removeRunnerPins()
        var nearbyRunnersDisplayed: [PFUser] = []
        
        
        // Flow 3.2 - checkProximityZone for runners at the race
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            
            // Flow 3.2.1 - if there are no runners, don't display any
            
            if ((runnerLocations?.isEmpty) == true) {
                self.areTargetRunnersNearby = false
                self.areRunnersNearby = false
                
                self.targetRunnerName.isHidden = true
                self.targetRunnerETA.isHidden = true
                self.targetRunnerCheers.isHidden = true
                self.targetRunnerTrack.isHidden = true
                
                self.general1RunnerPic.isHidden = true
                self.general1RunnerName.isHidden = true
                self.general1RunnerETA.isHidden = true
                self.general1RunnerCheers.isHidden = true
                self.general1RunnerTrack.isHidden = true
                
                self.general2RunnerPic.isHidden = true
                self.general2RunnerName.isHidden = true
                self.general2RunnerETA.isHidden = true
                self.general2RunnerCheers.isHidden = true
                self.general2RunnerTrack.isHidden = true
                
                self.general3RunnerPic.isHidden = true
                self.general3RunnerName.isHidden = true
                self.general3RunnerETA.isHidden = true
                self.general3RunnerCheers.isHidden = true
                self.general3RunnerTrack.isHidden = true
            }
                
            // Flow 3.2.1  - if there are runners at the race, update their info
            else {
                self.runnerLocations = runnerLocations!
                
                // Flow 3.2.1.1 - if we don't have runner profiles, get them
                self.updateRunnerProfiles(runnerLocations!)
                
                // Flow 3.2.1.2 - get cheer counts
                self.updateRunnerCheers(runnerLocations!)
                
                // Flow 3.2.1.3 - get ETAs of runners
                self.updateRunnerETAs(runnerLocations!)
                
                
                // Flow 3.2.1.4 - if target runner was already set, update its labels
                if self.targetRunner.objectId != nil {
                    self.updateTargetRunnerStatus(self.targetRunner)
                }
                
                // Flow 3.2.1.5 - sort out target & general runners
                self.optimizedRunners.considerAffinity(self.runnerLocations) { (affinities) -> Void in
                    print("affinities \(affinities)")
                    
                    for (runner, runnerLoc) in runnerLocations! {
                        
                        // Flow 3.2.1.5.1 - calculate the distance between spectator and a runner
                        
                        let runnerCLLoc = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                        let dist = runnerCLLoc.distance(from: self.optimizedRunners.locationMgr.location!)
                        print(runner.username!, dist)
                        
                        // Flow 3.2.1.5.2 - for each runner, determine if target or general, and handle separately based on distance
                        for affinity in affinities {
                            
                            if runner == affinity.0 {
                                //Goal: Show target runners throughout the race
                                if dist > 400 { //if runner is more than 2km away (demo: 400)
                                    if affinity.1 == 10 { //if target runner, display runner
                                        self.addRunnerPin(runner, runnerType: 1)
                                        self.nearbyTargetRunners[runner.objectId!] = false
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, don't add them yet
                                        self.areRunnersNearby = false
                                    }
                                }
                                    
                                    //Goal: Show all runners near me, including target runners
                                else if dist > 300 && dist <= 400 { //if runner is between 1-2km away (demo: 300-400)
                                    if affinity.1 == 10 { //if target runner, display runner
                                        self.addRunnerPin(runner, runnerType: 1)
                                        self.nearbyTargetRunners[runner.objectId!] = true
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, display runner
                                       self.areRunnersNearby = true
                                        self.updateGeneralRunnerStatus(runner, runnerType: "general")
                                        nearbyRunnersDisplayed.append(runner)
                                        
                                    }
                                }
                                    
                                    //Goal: if target runner is close, disable general runners & only show targets.
                                else if dist > 250 && dist <= 300 { //if runner is between 500m - 1k away (demo: 250-300)
                                    if affinity.1 == 10 { //if target runner, display runner
                                        self.addRunnerPin(runner, runnerType: 1)
                                        self.nearbyTargetRunners[runner.objectId!] = true
                                        self.areTargetRunnersNearby = true
                                        self.disableGeneralRunners()
                                        self.areRunnersNearby = false
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                        if !self.areTargetRunnersNearby {
                                            self.areRunnersNearby = true
                                            self.updateGeneralRunnerStatus(runner, runnerType: "general")
                                            nearbyRunnersDisplayed.append(runner)
                                        }
                                    }
                                }
                                    
                                    //Goal: If target runner is close, only show them. If not, then continue to show all runners
                                else if dist <= 250 { //if runner is less than 500m away (demo: 250)
                                    if affinity.1 == 10 { //if target runner, display runner & notify
                                        
                                        self.nearbyRunnersTimer.invalidate()
                                        self.nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
                                        self.addRunnerPin(runner, runnerType: 1)
                                        self.targetRunnerTrack.isEnabled = true
                                        self.nearbyTargetRunners[runner.objectId!] = true
                                        self.areTargetRunnersNearby = true
                                        self.disableGeneralRunners()
                                        self.areRunnersNearby = false
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                        
                                        if !self.areTargetRunnersNearby {
                                            self.areRunnersNearby = true
                                            self.updateGeneralRunnerStatus(runner, runnerType: "general")
                                            nearbyRunnersDisplayed.append(runner)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    self.nearbyTargetRunners = self.optimizedRunners.targetRunners
                    self.optimizedRunners.saveDisplayedRunners(nearbyRunnersDisplayed)
                }
            }
        }
    }
    
    // get the name and picture for each runner in runner Locations, store to runnerProfiles
    func updateRunnerProfiles(_ runnerLocations: [PFUser: PFGeoPoint]) {
        
        for (runner, runnerLoc) in runnerLocations {
            

            if runnerProfiles[runner.objectId!] == nil {
                nearbyRunners.getRunnerProfile(runner.objectId!) { (runnerProfile) -> Void in
                    
                    self.runnerProfiles[runner.objectId!] = runnerProfile
                    print("runner profile did not exist, added  \(String(describing: runner.username))")
                    print(self.runnerProfiles)
                }
            }
            else {
                print("runner profile exists, will not query")
            }
        }
    }
    
    // get the cheer counts for each runner
    func updateRunnerCheers(_ runnerLocations: [PFUser: PFGeoPoint]) {
        self.optimizedRunners.considerNeed(runnerLocations, result: { (needs) -> Void in
            self.runnerCheers = needs
            print("needs: \(self.runnerCheers)")
        })
    }
    
    // get the ETAs for each runner
    func updateRunnerETAs(_ runnerLocations: [PFUser: PFGeoPoint]) {
        self.optimizedRunners.considerConvenience(runnerLocations, result: { (conveniences) -> Void in
            self.runnerETAs = conveniences
            print("ETAs: \(self.runnerETAs)")
        })
    }
    
    // get a runner's name
    func getRunnerName(_ runnerObjID: String, runnerProfiles: [String:[String:AnyObject]]) -> String {
        
        if runnerProfiles[runnerObjID] != nil {
            let runnerProfile = runnerProfiles[runnerObjID]
            let name = runnerProfile!["name"] as! String
            return name
        }
        else {
            print("No name found, using generic")
            let name = ""
            return name
        }
    }
    
    // get a runner's picture
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
    
    // get a runner's cheer count
    func getRunnerCheers(_ runner: PFUser) -> (Int, UIColor){
        
        var cheerCount: Int = Int()
        var textColor = targetRunnerName.textColor
        
        for user in runnerCheers {
            if runner.objectId  == user.0.objectId {
                cheerCount = user.1
                print("cheers count for in getCheers: \(String(describing: cheerCount))")
            }
        }
        
        let minCheers = runnerCheers.values.min()
        let maxCheers = runnerCheers.values.max()
        let cheersDiff = maxCheers! - minCheers!
        let third = Int(cheersDiff/3)
        
        if cheerCount <= third {
            textColor = redLabel.textColor
        }
        
        return (cheerCount, textColor!)
    }
    
    // get a runner's ETA
    func getRunnerETA(_ runner: PFUser) -> Int{
        
        var ETA: Int = Int()
        
        for user in runnerETAs {
            if runner.objectId  == user.0.objectId {
                ETA = user.1
                print("ETA for in getCheers: \(String(describing: ETA))")
            }
        }
        return ETA
    }
    
    func updateTargetRunnerStatus(_ runner: PFUser) {
        
        let targetPic = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
        targetRunnerNameText = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
        let (cheers, cheersColor) = getRunnerCheers(runner)
        let ETA = getRunnerETA(runner)
        
        print("Target runner: \(targetRunnerNameText)")
        print("cheers count for target: \(cheers)")
        print("ETA for target: \(ETA)")
        
        targetRunnerPic.image = targetPic
        targetRunnerName.text = targetRunnerNameText
        targetRunnerCheers.text = String(format: "cheers: %d", cheers)
        if ETA == 0 {
            targetRunnerETA.text = "ETA: <1 mi"
            targetRunnerETA.textColor = redLabel.textColor
        }
        else { targetRunnerETA.text = String(format: "ETA: %d mi", ETA) }
        
        targetRunnerCheers.textColor = cheersColor
        targetRunnerETA.textColor = cheersColor
        
        targetRunnerName.isHidden = false
        targetRunnerETA.isHidden = false
        targetRunnerCheers.isHidden = false
        
    }
    
    func updateGeneralRunnerStatus(_ runner: PFUser, runnerType: String) {
        
        if areRunnersNearby == true && areTargetRunnersNearby == false {
            idleTimeBanner.isHidden = true
        }
        else {
            idleTimeBanner.isHidden = false
        }
        
        if !self.runnerProfiles.isEmpty {
                
            if runnerType == "general" {
                
                let generalRunners = self.optimizedRunners.generalRunners
                print("generalRunners in dashboardVC: \(generalRunners)")
                if generalRunners.count == 0 {
                    
                    //hide all labels
                    general1RunnerPic.isHidden = true
                    general1RunnerName.isHidden = true
                    general1RunnerETA.isHidden = true
                    general1RunnerCheers.isHidden = true
                    general1RunnerTrack.isHidden = true
                    
                    general2RunnerPic.isHidden = true
                    general2RunnerName.isHidden = true
                    general2RunnerETA.isHidden = true
                    general2RunnerCheers.isHidden = true
                    general2RunnerTrack.isHidden = true
                    
                    general3RunnerPic.isHidden = true
                    general3RunnerName.isHidden = true
                    general3RunnerETA.isHidden = true
                    general3RunnerCheers.isHidden = true
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
                    let (cheers, cheersColor) = getRunnerCheers(general1Runner)
                    let ETA = getRunnerETA(general1Runner)
                
                    general1RunnerName.text = name
                    general1RunnerCheers.text = String(format: "cheers: %d", cheers)
                    if ETA == 0 {
                        general1RunnerETA.text = "ETA: <1 mi"
                        general1RunnerETA.textColor = redLabel.textColor
                    }
                    else { general1RunnerETA.text = String(format: "ETA: %d mi", ETA) }
                    general1RunnerCheers.textColor = cheersColor
                    
                    general1RunnerPic.isHidden = false
                    general1RunnerName.isHidden = false
                    general1RunnerETA.isHidden = false
                    general1RunnerCheers.isHidden = false
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
                    let (cheers1, cheersColor1) = getRunnerCheers(general1Runner)
                    let ETA1 = getRunnerETA(general1Runner)
                    
                    general1RunnerName.text = name1
                    general1RunnerCheers.text = String(format: "cheers: %d", cheers1)
                    if ETA1 == 0 {
                        general1RunnerETA.text = "ETA: <1 mi"
                        general1RunnerETA.textColor = redLabel.textColor
                    }
                    else { general1RunnerETA.text = String(format: "ETA: %d mi", ETA1) }
                    general1RunnerCheers.textColor = cheersColor1
                    
                    general1RunnerPic.isHidden = false
                    general1RunnerName.isHidden = false
                    general1RunnerETA.isHidden = false
                    general1RunnerCheers.isHidden = false
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
                    let (cheers2, cheersColor2) = getRunnerCheers(general2Runner)
                    let ETA2 = getRunnerETA(general2Runner)
                    
                    general2RunnerName.text = name2
                    general2RunnerCheers.text = String(format: "cheers: %d", cheers2)
                    if ETA2 == 0 {
                        general2RunnerETA.text = "ETA: <1 mi"
                        general2RunnerETA.textColor = redLabel.textColor
                    }
                    else { general2RunnerETA.text = String(format: "ETA: %d mi", ETA2) }
                    general2RunnerCheers.textColor = cheersColor2
                    
                    general2RunnerPic.isHidden = false
                    general2RunnerName.isHidden = false
                    general2RunnerETA.isHidden = false
                    general2RunnerCheers.isHidden = false
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
                    let (cheers1, cheersColor1) = getRunnerCheers(general1Runner)
                    let ETA1 = getRunnerETA(general1Runner)
                    
                    general1RunnerName.text = name1
                    general1RunnerCheers.text = String(format: "cheers: %d", cheers1)
                    if ETA1 == 0 {
                        general1RunnerETA.text = "ETA: <1 mi"
                        general1RunnerETA.textColor = redLabel.textColor
                    }
                    else { general1RunnerETA.text = String(format: "ETA: %d mi", ETA1) }
                    general1RunnerCheers.textColor = cheersColor1
                    
                    general1RunnerPic.isHidden = false
                    general1RunnerName.isHidden = false
                    general1RunnerETA.isHidden = false
                    general1RunnerCheers.isHidden = false
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
                    let (cheers2, cheersColor2) = getRunnerCheers(general2Runner)
                    let ETA2 = getRunnerETA(general2Runner)
                    
                    general2RunnerName.text = name2
                    general2RunnerCheers.text = String(format: "cheers: %d", cheers2)
                    if ETA2 == 0 {
                        general2RunnerETA.text = "ETA: <1 mi"
                        general2RunnerETA.textColor = redLabel.textColor
                    }
                    else { general2RunnerETA.text = String(format: "ETA: %d mi", ETA2) }
                    general2RunnerCheers.textColor = cheersColor2
                    
                    general2RunnerPic.isHidden = false
                    general2RunnerName.isHidden = false
                    general2RunnerETA.isHidden = false
                    general2RunnerCheers.isHidden = false
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
                    let (cheers3, cheersColor3) = getRunnerCheers(general3Runner)
                    let ETA3 = getRunnerETA(general3Runner)
                    
                    general3RunnerName.text = name3
                    general3RunnerCheers.text = String(format: "cheers: %d", cheers3)
                    if ETA3 == 0 {
                        general3RunnerETA.text = "ETA: <1 mi"
                        general3RunnerETA.textColor = redLabel.textColor
                    }
                    else { general3RunnerETA.text = String(format: "ETA: %d mi", ETA3) }
                    general3RunnerCheers.textColor = cheersColor3
                    
                    general3RunnerPic.isHidden = false
                    general3RunnerName.isHidden = false
                    general3RunnerETA.isHidden = false
                    general3RunnerCheers.isHidden = false
                    general3RunnerTrack.isHidden = false
                }
            }
        }
    }
    
    func disableGeneralRunners() {
        
        general1RunnerETA.textColor = general1RunnerName.textColor
        general2RunnerETA.textColor = general1RunnerName.textColor
        general3RunnerETA.textColor = general1RunnerName.textColor
            
        general1RunnerCheers.textColor = general1RunnerName.textColor
        general2RunnerCheers.textColor = general1RunnerName.textColor
        general3RunnerCheers.textColor = general1RunnerName.textColor
        
//        general1RunnerTrack.isEnabled = false
//        general2RunnerTrack.isEnabled = false
//        general3RunnerTrack.isEnabled = false
//        
//        general1RunnerTrack.setTitleColor(UIColor.gray, for: UIControlState.disabled)
//        general2RunnerTrack.setTitleColor(UIColor.gray, for: UIControlState.disabled)
//        general3RunnerTrack.setTitleColor(UIColor.gray, for: UIControlState.disabled)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        else {
            let annotationView = PickRunnerAnnotationView(annotation: annotation, reuseIdentifier: "Runner")
            annotationView.canShowCallout = true
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        print("\(String(describing: view.annotation?.title)) has been tapped")
        if (view is PickRunnerAnnotationView) {
            
            targetRunnerTrack.isHidden = false
            let ann = view.annotation as! PickRunnerAnnotation
            let runnerObjID = ann.runnerObjID
            do {
                targetRunner = try PFQuery.getUserObject(withId: runnerObjID!)
            }
            catch {
                print("ERROR: unable to get runner")
            }
            
            updateTargetRunnerStatus(targetRunner)
        }
    }
    
    func addRunnerPin(_ runner: PFUser, runnerType: Int) {
        
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in
            let name = self.getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
            let coordinate = runnerLoc
            let title = name
            let runnerObjID = runner.objectId
            let type = RunnerType(rawValue: runnerType) //type would be 0 if any runner and 1 if it's my runner
            let annotation = PickRunnerAnnotation(coordinate: coordinate, title: title, type: type!, runnerObjID: runnerObjID!)
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func removeRunnerPins() {
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        print("annotationsToRemove \(annotationsToRemove)")
        mapView.removeAnnotations(annotationsToRemove)
    }
    
    func sendLocalNotification_any() {
        if areRunnersNearby == true && areTargetRunnersNearby == false {
            
            if UIApplication.shared.applicationState == .background {
                let localNotification = UILocalNotification()
                
                var spectatorInfo = [String: AnyObject]()
                spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
                spectatorInfo["source"] = "generalRunnerNotification" as AnyObject
                spectatorInfo["receivedNotification"] = true as AnyObject
                spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
                
                
                localNotification.alertBody = "Check in on your favorite runners!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                
                spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
                localNotification.userInfo = spectatorInfo
                
                UIApplication.shared.presentLocalNotificationNow(localNotification)
            }
        }
            
        else {
            print("local notification: no runners nearby")
        }
    }
    
    func sendLocalNotification_target() {
        
        if areTargetRunnersNearby == true {
            
            for (runnerObjId, isNearby) in nearbyTargetRunners {
                
                if isNearby == true {
                    
                    let name =  getRunnerName(runnerObjId, runnerProfiles: self.runnerProfiles)
                    
                    if UIApplication.shared.applicationState == .background {
                        
                        let localNotification = UILocalNotification()
                        
                        var spectatorInfo = [String: AnyObject]()
                        spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
                        spectatorInfo["source"] = "targetRunnerNotification" as AnyObject
                        spectatorInfo["receivedNotification"] = true as AnyObject
                        spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
                        
                        localNotification.alertBody =  name + " is nearby, get ready to support them!"
                        localNotification.soundName = UILocalNotificationDefaultSoundName
                        localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                        
                        spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
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
        let source = "dashboard"
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(targetRunner, source) { (cheerSaved) -> Void in
            
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
        let source = "dashboard"
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general1Runner, source) { (cheerSaved) -> Void in
            
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
        let source = "dashboard"
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general2Runner, source) { (cheerSaved) -> Void in
            
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
        let source = "dashboard"
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(general3Runner, source) { (cheerSaved) -> Void in
            
            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegue(withIdentifier: "trackRunner", sender: nil)
    }
}
