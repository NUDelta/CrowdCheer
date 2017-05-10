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
    
        
        // Flow 1 - Hide all runner information
        
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
        //find nearby runners and display those runners

        
        // Flow 3.1 - remove R* pins from map and reset nearbyRunners
        removeRunnerPins()
        var nearbyRunnersDisplayed: [PFUser] = []
        
        
        // Flow 3.2 - checkProximityZone for runners at the race
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            
            // Flow 3.2.1 - if there are no runners, don't display any
            
            if ((runnerLocations?.isEmpty) == true) {
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
                
                // Flow 3.2.1.4 - sort out target & general runners
                self.optimizedRunners.considerAffinity(self.runnerLocations) { (affinities) -> Void in
                    print("affinities \(affinities)")
                    
                    for (runner, runnerLoc) in runnerLocations! {
                        
                        // Flow 3.2.1.4.1 - calculate the distance between spectator and a runner
                        
                        let runnerCoord = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                        let dist = runnerCoord.distance(from: self.optimizedRunners.locationMgr.location!)
                        print(runner.username!, dist)
                        
                        // Flow 3.2.1.4.2 - for each runner, determine if target or general, and handle separately based on distance
                        for affinity in affinities {
                            
                            var isTargetRunnerNear = false
                            if runner == affinity.0 {
                                //Goal: Show target runners throughout the race
                                if dist > 2000 { //if runner is more than 2km away (demo: 400)
                                    if affinity.1 == 10 { //if target runner, display runner
        //                                self.targetRunnerLoading.isHidden = true
        //                                self.targetRunnerETA.isHidden = false
        //                                self.targetRunnerETA.text = (name) + " is more than 10 min away"
                                        
                                        self.getTargetRunnerStatus(runner)
                                        self.targetRunnerTrackingStatus[runner.objectId!] = true
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, don't add them yet
                                        //do nothing
                                    }
                                }
                                    
                                    //Goal: Show all runners near me, including target runners
                                else if dist > 1000 && dist <= 2000 { //if runner is between 1-2km away (demo: 300-400)
                                    if affinity.1 == 10 { //if target runner, display runner
//                                        self.targetRunnerETA.isHidden = true
//                                        self.targetRunnerLoading.isHidden = true
        //                                self.targetRunner5More.isHidden = false
        //                                self.targetRunner5More.text = (name) + " is more than 5 min away"
                                        
                                        self.getTargetRunnerStatus(runner)
                                        self.targetRunnerTrackingStatus[runner.objectId!] = true
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, display runner
                                        self.getRunnerProfile(runner, runnerType: "general")
                                        nearbyRunnersDisplayed.append(runner)
                                        self.areRunnersNearby = true
                                    }
                                }
                                    
                                    //Goal: if target runner is close, disable general runners & only show targets.
                                else if dist > 500 && dist <= 1000 { //if runner is between 500m - 1k away (demo: 250-300)
                                    if affinity.1 == 10 { //if target runner, display runner
    //                                self.targetRunner5More.isHidden = true
    //                                self.targetRunnerLoading.isHidden = true
    //                                self.targetRunner5Less.isHidden = false
    //                                self.targetRunner5Less.text = (name) + " is less than 5 min away"
                                        
                                        self.getTargetRunnerStatus(runner)
                                        self.disableGeneralRunners()
                                        self.targetRunnerTrackingStatus[runner.objectId!] = true
                                        nearbyRunnersDisplayed.append(runner)
                                        
                                        isTargetRunnerNear = true
                                    }
                                    else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                        if !isTargetRunnerNear {
                                            self.getRunnerProfile(runner, runnerType: "general")
                                            nearbyRunnersDisplayed.append(runner)
                                            self.areRunnersNearby = true
                                        }
                                    }
                                }
                                    
                                    //Goal: If target runner is close, only show them. If not, then continue to show all runners
                                else if dist <= 500 { //if runner is less than 500m away (demo: 250)
                                    if affinity.1 == 10 { //if target runner, display runner & notify
                                        
                                        self.nearbyRunnersTimer.invalidate()
                                        self.nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
                                        
//                                        self.targetRunner5Less.isHidden = true
//                                        self.targetRunnerLoading.isHidden = true
//                                        self.targetRunnerTimeToCheer.text = (name) + " is nearby, support them now!"
//                                        self.targetRunnerTimeToCheer.isHidden = false
                                        
                                        self.getTargetRunnerStatus(runner) // show cheers & ETA for the runner
                                        self.targetRunnerTrack.isEnabled = true
                                        self.targetRunnerTrackingStatus[runner.objectId!] = true
                                        nearbyRunnersDisplayed.append(runner)
                                        
                                        self.areTargetRunnersNearby = true
                                        isTargetRunnerNear = true
                                    }
                                    else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                        
                                        if dist < 300 {
                                            // these runners are general and close by
                                            // we need the distance that they've run
                                            // calculate the distance R* has run (how do we know which R*?)
                                            
                                        }
                                
                                        
                                        if !isTargetRunnerNear {
                                            self.getRunnerProfile(runner, runnerType: "general")
                                            nearbyRunnersDisplayed.append(runner)
                                            self.areRunnersNearby = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    self.targetRunnerTrackingStatus = self.optimizedRunners.targetRunners
                    print("targetRunnerTrackingStatus inside considerAffinity: \(self.targetRunnerTrackingStatus)")
                    self.optimizedRunners.saveDisplayedRunners(nearbyRunnersDisplayed)
                }
            }
        }
    }
    
    // get the name and picture for each runner in runner Locations, store to runnerProfiles
    func updateRunnerProfiles(_ runnerLocations: [PFUser: PFGeoPoint]) {
        
        for (runner, runnerLoc) in runnerLocations {
            
            print("is \(String(describing: runner.username)) missing \(String(describing: runnerProfiles[runner.objectId!]))")
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
            print("needs: \(self.runnerCheers)")
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
    func getRunnerCheers(_ runner: PFUser) -> Int{
        let cheerCount = 0
        
        if self.runnerCheers[runner] != nil {
            let cheerCount = self.runnerCheers[runner]
            print("cheers count for in getCheers: \(String(describing: cheerCount))")
        }
        else {
            print("No cheers found, using generic")
        }
        return cheerCount
    }
    
    // get a runner's ETA
    func getRunnerETA(_ runner: PFUser) -> Int{
        let ETA = 0
        
        if self.runnerETAs[runner] != nil {
            let ETA = self.runnerETAs[runner]
            print("ETA for in getCheers: \(String(describing: ETA))")
        }
        else {
            print("No cheers found, using generic")
        }
        return ETA
    }
    
    func getRunnerProfile(_ runner: PFUser, runnerType: String) {
        
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
                    let cheers = getRunnerCheers(general1Runner)
                
                    general1RunnerName.text = name
                    general1RunnerCheers.text = cheers
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
                    let cheers1 = getRunnerCheers(general1Runner)
                    
                    general1RunnerName.text = name1
                    general1RunnerCheers.text = cheers1
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
                    let cheers2 = getRunnerCheers(general2Runner)
                    
                    general2RunnerName.text = name2
                    general2RunnerCheers.text = cheers2
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
                    let cheers1 = getRunnerCheers(general1Runner)
                    
                    general1RunnerName.text = name1
                    general1RunnerCheers.text = cheers1
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
                    let cheers2 = getRunnerCheers(general2Runner)
                    
                    general2RunnerName.text = name2
                    general2RunnerCheers.text = cheers2
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
                    let cheers3 = getRunnerCheers(general3Runner)
                    
                    general3RunnerName.text = name3
                    general3RunnerCheers.text = cheers3
                    general3RunnerPic.isHidden = false
                    general3RunnerName.isHidden = false
                    general3RunnerETA.isHidden = false
                    general3RunnerCheers.isHidden = false
                    general3RunnerTrack.isHidden = false
                }
            }
        }
    }
    
    func getTargetRunnerStatus(_ runner: PFUser) {
        
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in
            
            self.addRunnerPin(runner, runnerLoc: runnerLoc, runnerType: 1)
        }
        
        let cheers = getRunnerCheers(runner)
//        let ETA = getRunnerETA(runner)
        
        self.targetRunnerCheers.text = cheers
        
        if contextPrimer.pace == "" {
            //            self.targetRunnerPace.isHidden = true
            //            self.targetRunnerDistance.isHidden = true
            //            self.targetRunnerTime.isHidden = true
        }
            
        else {
            //            self.targetRunnerPace.text = (contextPrimer.pace as String)
            //            self.targetRunnerDistance.text = String(format: " %.02f", contextPrimer.distance) + "mi"
            //            self.targetRunnerTime.text = (contextPrimer.duration as String) + "s"
            //
            //            self.targetRunnerPace.isHidden = false
            //            self.targetRunnerDistance.isHidden = false
            //            self.targetRunnerTime.isHidden = false
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
            targetRunnerNameText = getRunnerName(runnerObjID!, runnerProfiles: self.runnerProfiles)
            targetRunnerName.text = targetRunnerNameText
            let cheers = getRunnerCheers(targetRunner)
            let ETA = getRunnerETA(targetRunner)
            
            print("Selected runner: \(targetRunnerNameText)")
            print("cheers count for target: \(cheers)")
            print("ETA for target: \(ETA)")
            
            targetRunnerCheers.text = String(format: "cheers: %f", cheers)
            targetRunnerETA.text = String(format: "ETA: %f", ETA)
            
            targetRunnerName.isHidden = false
            targetRunnerETA.isHidden = false
            targetRunnerCheers.isHidden = false
            
        }
    }
    
    func addRunnerPin(_ runner: PFUser, runnerLoc: CLLocationCoordinate2D, runnerType: Int) {
        
        let name = runner.value(forKey: "name")
        let coordinate = runnerLoc
        let title = (name as? String)
        let runnerObjID = runner.objectId
        let type = RunnerType(rawValue: runnerType) //type would be 0 if any runner and 1 if it's my runner
        let annotation = PickRunnerAnnotation(coordinate: coordinate, title: title!, type: type!, runnerObjID: runnerObjID!)
        mapView.addAnnotation(annotation)
    }
    
    func removeRunnerPins() {
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        print("annotationsToRemove \(annotationsToRemove)")
        mapView.removeAnnotations(annotationsToRemove)
    }
    
    func sendLocalNotification_any() {
        if areRunnersNearby == true {
            
            if UIApplication.shared.applicationState == .background {
                let localNotification = UILocalNotification()
                
                var spectatorInfo = [String: AnyObject]()
                spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
                spectatorInfo["source"] = "generalRunnerNotification" as AnyObject
                spectatorInfo["receivedNotification"] = true as AnyObject
                spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
                
                
                localNotification.alertBody = "Cheer for runners near you!"
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
        
        let name = targetRunnerNameText
        
        if areTargetRunnersNearby == true {
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
