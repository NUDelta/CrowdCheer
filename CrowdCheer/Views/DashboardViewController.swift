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
    @IBOutlet weak var targetRunnerTrack: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    var targetRunner: PFUser = PFUser()
    
    @IBOutlet weak var general1RunnerPic: UIImageView!
    @IBOutlet weak var general1RunnerName: UILabel!
    @IBOutlet weak var general1RunnerETA: UILabel!
    @IBOutlet weak var general1RunnerTrack: UIButton!
    var general1Runner: PFUser = PFUser()
    
    @IBOutlet weak var general2RunnerPic: UIImageView!
    @IBOutlet weak var general2RunnerName: UILabel!
    @IBOutlet weak var general2RunnerETA: UILabel!
    @IBOutlet weak var general2RunnerTrack: UIButton!
    var general2Runner: PFUser = PFUser()
    
    @IBOutlet weak var general3RunnerPic: UIImageView!
    @IBOutlet weak var general3RunnerName: UILabel!
    @IBOutlet weak var general3RunnerETA: UILabel!
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
    var lastGeneralRunnerNotificationTime = NSDate()
    var timeSinceLastNotification: Double = Double()
    var areRunnersNearby: Bool = Bool()
    var areTargetRunnersNearby: Bool = Bool()
    var targetRunnerNameText: String = ""
    var nearbyTargetRunners = [String: Bool]()
    var nearbyGeneralRunners = [PFUser: Bool]()
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
        targetRunnerTrack.isHidden = true
        
        general1RunnerPic.isHidden = true
        general1RunnerName.isHidden = true
        general1RunnerETA.isHidden = true
        general1RunnerTrack.isHidden = true
        
        general2RunnerPic.isHidden = true
        general2RunnerName.isHidden = true
        general2RunnerETA.isHidden = true
        general2RunnerTrack.isHidden = true
        
        general3RunnerPic.isHidden = true
        general3RunnerName.isHidden = true
        general3RunnerETA.isHidden = true
        general3RunnerTrack.isHidden = true
        
        idleTimeBanner.isHidden = true
        
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        areTargetRunnersNearby = false
        areRunnersNearby = false
        interval = 30
        lastGeneralRunnerNotificationTime = NSDate()
        timeSinceLastNotification = 0.0
        
        
        //initialize mapview
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        
        
        // Flow 2 - check once for any nearby runners on view load
        userMonitorTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(DashboardViewController.monitorUser), userInfo: nil, repeats: false)
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: false)
        nearbyGeneralRunnersTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(DashboardViewController.notifyForGeneralRunners), userInfo: nil, repeats: false)
        nearbyTargetRunnersTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(DashboardViewController.sendLocalNotification_target), userInfo: nil, repeats: false)
        
        
        // Flow 3 - every interval, log spectator loc and update nearby runners
        
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
        
        // Flow 4 - every interval, notify spectators if 1) R runners are nearby and 2) R* runners are nearby
        
        nearbyGeneralRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(DashboardViewController.notifyForGeneralRunners), userInfo: nil, repeats: true)
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
                self.targetRunnerTrack.isHidden = true
                
                self.general1RunnerPic.isHidden = true
                self.general1RunnerName.isHidden = true
                self.general1RunnerETA.isHidden = true
                self.general1RunnerTrack.isHidden = true
                
                self.general2RunnerPic.isHidden = true
                self.general2RunnerName.isHidden = true
                self.general2RunnerETA.isHidden = true
                self.general2RunnerTrack.isHidden = true
                
                self.general3RunnerPic.isHidden = true
                self.general3RunnerName.isHidden = true
                self.general3RunnerETA.isHidden = true
                self.general3RunnerTrack.isHidden = true
            }
                
            // Flow 3.2.1  - if there are runners at the race, update their info
            else {
                self.runnerLocations = runnerLocations!
                
                // Flow 3.2.1.1 - if we don't have runner profiles, get them
                self.updateRunnerProfiles(runnerLocations!)
                
                // Flow 3.2.1.2 - update areRunnersNearby and areTargetRunnersNearby
                self.updateNearbyRunnerStatus()
                
                // Flow 3.2.1.3 - get cheer counts
                self.updateRunnerCheers(runnerLocations!)
                
                // Flow 3.2.1.4 - get ETAs of runners
                self.updateRunnerETAs(runnerLocations!)
                
                // Flow 3.2.1.5 - if target runner was already set, update its labels
                if self.targetRunner.objectId != nil {
                    self.updateTargetRunnerStatus(self.targetRunner)
                }
                
                // Flow 3.2.1.6 - sort out target & general runners
                self.optimizedRunners.considerAffinity(self.runnerLocations) { (affinities) -> Void in
                    print("affinities \(affinities)")
                    
                    // Empty Nearby Runners and recheck
                    self.nearbyGeneralRunners = [:]
                    self.nearbyTargetRunners = [:]
                    
                    for (runner, runnerLoc) in runnerLocations! {
                        
                        // Flow 3.2.1.6.1 - calculate the distance between spectator and a runner
                        
                        let runnerCLLoc = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                        let dist = runnerCLLoc.distance(from: self.optimizedRunners.locationMgr.location!)
                        print(runner.username!, dist)
                        
                        // Flow 3.2.1.6.2 - for each runner, determine if target or general, and handle separately based on distance
                        for affinity in affinities {
                            
                            if runner == affinity.0 {
                                //Goal: Show target runners throughout the race
                                if dist > 2000 { //if runner is more than 2km away (demo: 400)
                                    if affinity.1 == 10 { //if target runner, display runner
                                        self.addRunnerPin(runner, runnerType: 1)
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, don't add them yet
                                    }
                                }
                                    
                                    //Goal: Show all runners near me, including target runners
                                else if dist > 1000 && dist <= 2000 { //if runner is between 1-2km away (demo: 300-400)
                                    if affinity.1 == 10 { //if target runner, display runner
                                        self.addRunnerPin(runner, runnerType: 1)
                                        self.nearbyTargetRunners[runner.objectId!] = true
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, display runner
                                        self.nearbyGeneralRunners[runner] = true
                                        self.updateGeneralRunnerStatus(runner, runnerType: "general")
                                        nearbyRunnersDisplayed.append(runner)
                                        
                                    }
                                }
                                    
                                    //Goal: if target runner is close, disable general runners & only show targets.
                                else if dist > 500 && dist <= 1000 { //if runner is between 500m - 1k away (demo: 250-300)
                                    if affinity.1 == 10 { //if target runner, display runner
                                        self.addRunnerPin(runner, runnerType: 1)
                                        self.nearbyTargetRunners[runner.objectId!] = true
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                        self.nearbyGeneralRunners[runner] = true
                                        self.updateGeneralRunnerStatus(runner, runnerType: "general")
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                }
                                    
                                    //Goal: If target runner is close, only show them. If not, then continue to show all runners
                                else if dist <= 500 { //if runner is less than 500m away (demo: 250)
                                    if affinity.1 == 10 { //if target runner, display runner & notify
                                        
                                        self.nearbyRunnersTimer.invalidate()
                                        self.nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
                                        self.addRunnerPin(runner, runnerType: 1)
                                        self.targetRunnerTrack.isEnabled = true
                                        self.nearbyTargetRunners[runner.objectId!] = true
                                        self.disableGeneralRunners()
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                    else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                        
                                        self.nearbyGeneralRunners[runner] = true
                                        self.updateGeneralRunnerStatus(runner, runnerType: "general")
                                        nearbyRunnersDisplayed.append(runner)
                                    }
                                }
                            }
                        }
                    }
                    
//                    self.nearbyTargetRunners = self.optimizedRunners.targetRunners
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
                print("ETA in getETA: \(String(describing: ETA))")
            }
        }
        return ETA
    }
    
    func updateNearbyRunnerStatus() {
        if !self.nearbyGeneralRunners.isEmpty {
            self.areRunnersNearby = true
        }
        else {
            self.areRunnersNearby = false
            self.clearGeneralDashboard()
        }
        
        if !self.nearbyTargetRunners.isEmpty {
            self.areTargetRunnersNearby = true
        }
        else {
            self.areTargetRunnersNearby = false
        }
    }
    
    func updateTargetRunnerStatus(_ runner: PFUser) {
        
        self.updateNearbyRunnerStatus()
        
        let targetPic = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
        targetRunnerNameText = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
//        let (cheers, cheersColor) = getRunnerCheers(runner)
        let ETA = getRunnerETA(runner)
        
        print("Target runner: \(targetRunnerNameText)")
//        print("cheers count for target: \(cheers)")
        print("ETA for target: \(ETA)")
        
        targetRunnerPic.image = targetPic
        targetRunnerName.text = targetRunnerNameText
        if ETA < 2 {
            targetRunnerETA.text = "<1 mi away"
            targetRunnerETA.textColor = redLabel.textColor
            targetRunnerTrack.isHidden = false
        }
        else {
            targetRunnerETA.text = String(format: "%d mi away", ETA)
            targetRunnerETA.textColor = targetRunnerName.textColor
        }
        
        targetRunnerName.isHidden = false
        targetRunnerETA.isHidden = false
    }
    
    func updateGeneralRunnerStatus(_ runner: PFUser, runnerType: String) {
    
        self.updateNearbyRunnerStatus()
        
        var generalRunners = self.nearbyGeneralRunners
        print("generalRunners in dashboardVC: \(generalRunners)")
        
        if areRunnersNearby && !areTargetRunnersNearby {
            general1RunnerETA.textColor = redLabel.textColor
            general2RunnerETA.textColor = redLabel.textColor
            general3RunnerETA.textColor = redLabel.textColor
            idleTimeBanner.isHidden = false
        }
        
        else if areTargetRunnersNearby {
            disableGeneralRunners()
        }
        
        if generalRunners.count == 1 {
            updateGeneral1RunnerStatus((generalRunners.popFirst()?.key)!)
        }
            
        else if generalRunners.count == 2 {
            updateGeneral1RunnerStatus((generalRunners.popFirst()?.key)!)
            updateGeneral2RunnerStatus((generalRunners.popFirst()?.key)!)
            
        }
            
        else if generalRunners.count >= 2 {
            updateGeneral1RunnerStatus((generalRunners.popFirst()?.key)!)
            updateGeneral2RunnerStatus((generalRunners.popFirst()?.key)!)
            updateGeneral3RunnerStatus((generalRunners.popFirst()?.key)!)
        }
    }
    
    func updateGeneral1RunnerStatus(_ runner: PFUser) {
        general1Runner = runner
        let name = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
        let runnerPic = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
        //                    let (cheers, cheersColor) = getRunnerCheers(general1Runner)
        let ETA = getRunnerETA(general1Runner)
        
        general1RunnerName.text = name
        general1RunnerPic.image = runnerPic
        if ETA == 0 {
            general1RunnerETA.text = "<1 mi away"
        }
        else { general1RunnerETA.text = String(format: "%d mi away", ETA) }
        
        general1RunnerPic.isHidden = false
        general1RunnerName.isHidden = false
        general1RunnerETA.isHidden = false
        general1RunnerTrack.isHidden = false
    }
    
    func updateGeneral2RunnerStatus(_ runner: PFUser) {
        general2Runner = runner
        let name = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
        let runnerPic = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
        //                    let (cheers, cheersColor) = getRunnerCheers(general1Runner)
        let ETA = getRunnerETA(runner)
        
        general2RunnerName.text = name
        general2RunnerPic.image = runnerPic
        if ETA == 0 {
            general2RunnerETA.text = "<1 mi away"
        }
        else { general2RunnerETA.text = String(format: "%d mi away", ETA) }
        
        general2RunnerPic.isHidden = false
        general2RunnerName.isHidden = false
        general2RunnerETA.isHidden = false
        general2RunnerTrack.isHidden = false
    }
    
    func updateGeneral3RunnerStatus(_ runner: PFUser) {
        general3Runner = runner
        let name = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
        let runnerPic = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
        //                    let (cheers, cheersColor) = getRunnerCheers(general1Runner)
        let ETA = getRunnerETA(runner)
        
        general3RunnerName.text = name
        general3RunnerPic.image = runnerPic
        if ETA == 0 {
            general3RunnerETA.text = "<1 mi away"
        }
        else { general3RunnerETA.text = String(format: "%d mi away", ETA) }
        
        general3RunnerPic.isHidden = false
        general3RunnerName.isHidden = false
        general3RunnerETA.isHidden = false
        general3RunnerTrack.isHidden = false
    }
    
    func clearGeneralDashboard() {
        //hide all labels
        general1RunnerPic.isHidden = true
        general1RunnerName.isHidden = true
        general1RunnerETA.isHidden = true
        general1RunnerTrack.isHidden = true
        
        general2RunnerPic.isHidden = true
        general2RunnerName.isHidden = true
        general2RunnerETA.isHidden = true
        general2RunnerTrack.isHidden = true
        
        general3RunnerPic.isHidden = true
        general3RunnerName.isHidden = true
        general3RunnerETA.isHidden = true
        general3RunnerTrack.isHidden = true
        
        idleTimeBanner.isHidden = true
    }
    
    func disableGeneralRunners() {
        
        general1RunnerETA.textColor = general1RunnerName.textColor
        general2RunnerETA.textColor = general1RunnerName.textColor
        general3RunnerETA.textColor = general1RunnerName.textColor
        
        idleTimeBanner.isHidden = true
        
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
        
        if self.targetRunner.objectId == nil {
            self.targetRunner = runner
        }
        
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
    
    func notifyForGeneralRunners() {
        
        if UIApplication.shared.applicationState == .background {
            let random = arc4random_uniform(2)
            print("random: \(random)")
            print("time since last R notification: \(timeSinceLastNotification)s")
            
            let ETA = String(getRunnerETA(self.targetRunner))
            let name = getRunnerName(self.targetRunner.objectId!, runnerProfiles: self.runnerProfiles)
            
            if timeSinceLastNotification < Double(interval) {
                if random == 0 {
                    sendLocalNotification_general()
                }
                else if random == 1 {
                    sendLocalNotification_general_targetCheckin(name, ETA)
                }
            }
                
            else {
                let now = NSDate()
                
                if timeSinceLastNotification != 0 {
                    //NOTE: This value is actually going 30s ahead of what's used in the above if statement
                    timeSinceLastNotification = now.timeIntervalSince(lastGeneralRunnerNotificationTime as Date) + 2
                }
                
                if timeSinceLastNotification >= 60*1 {
                    if random == 0 {
                        sendLocalNotification_general()
                    }
                    else if random == 1 {
                        sendLocalNotification_general_targetCheckin(name, ETA)
                    }
                }
            }
        }
    }
    
    func sendLocalNotification_general() {
        if areRunnersNearby && !areTargetRunnersNearby {

            let localNotification = UILocalNotification()
            
            var spectatorInfo = [String: AnyObject]()
            spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
            spectatorInfo["source"] = "generalRunnerNotification" as AnyObject
            spectatorInfo["receivedNotification"] = true as AnyObject
            spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
            
            
            localNotification.alertBody = "Some nearby runners need your help! Cheer for them while you wait!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
            
            spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
            localNotification.userInfo = spectatorInfo
            
            UIApplication.shared.presentLocalNotificationNow(localNotification)
            
            let now = NSDate()
            lastGeneralRunnerNotificationTime = now
            
            if timeSinceLastNotification == 0 {
                timeSinceLastNotification = Double(interval)
            }
        }
    
        else {
            print("local notification: no runners nearby")
        }
    }
    
    func sendLocalNotification_general_targetCheckin(_ name: String, _ ETA: String) {
        if areRunnersNearby && !areTargetRunnersNearby {
            
            let localNotification = UILocalNotification()
            
            var spectatorInfo = [String: AnyObject]()
            spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
            spectatorInfo["source"] = "generalRunnerNotification_Target" as AnyObject
            spectatorInfo["receivedNotification"] = true as AnyObject
            spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
            
            
            localNotification.alertBody = name + " is " + ETA + "mi out and doing well, but some nearby runners need your help! Cheer for them while you wait!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
            
            spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
            localNotification.userInfo = spectatorInfo
            
            UIApplication.shared.presentLocalNotificationNow(localNotification)
            
            let now = NSDate()
            lastGeneralRunnerNotificationTime = now
            
            if timeSinceLastNotification == 0 {
                timeSinceLastNotification = Double(interval)
            }
            
        }
            
        else {
            print("local notification: no runners nearby")
        }
    }
    
    func sendLocalNotification_target() {
        
        if areTargetRunnersNearby {
            
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
