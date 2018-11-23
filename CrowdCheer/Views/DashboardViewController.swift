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
    @IBOutlet weak var nonIdleTimeBanner: UILabel!
    
    @IBOutlet weak var redLabel: UILabel!

    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerLocations = [PFUser: PFGeoPoint]()
    var runnerProfiles = [String:[String:AnyObject]]()
    var runnerAffinities = [PFUser: Int]()
    var runnerETAs = [PFUser: Int]()
    var runnerCheers = [PFUser: Int]()
    var userMonitorTimer_data: Timer = Timer()
    var userMonitorTimer_UI: Timer = Timer()
    var nearbyRunnersTimer_data: Timer = Timer()
    var nearbyRunnersTimer_UI: Timer = Timer()
    var lastGeneralRunnerNotificationTime = NSDate()
    var timeSinceLastNotification: Double = Double()
    var sendLocalNotification_targetCount: Int = Int()
    var areRunnersNearby: Bool = Bool()
    var areTargetRunnersNearby: Bool = Bool()
    var isSpectatorIdle: Bool = Bool()
    var didSpectatorCheerRecently: Bool = Bool()
    var targetRunnerNameText: String = ""
    var nearbyTargetRunners = [PFUser: Bool]()
    var nearbyGeneralRunners = [PFUser: Bool]()
    var intervalData: Int = Int()
    var intervalUI: Int = Int()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var contextPrimer: ContextPrimer = ContextPrimer()
    var verifiedDelivery: VerifiedDelivery = VerifiedDelivery()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "DashboardVC"
    
    override func viewDidAppear(_ animated: Bool) {
        
        viewWindowID = String(arc4random_uniform(10000000))
        
        let newViewWindowEvent = PFObject(className: "ViewWindows")
        newViewWindowEvent["userID"] = PFUser.current()!.objectId as AnyObject
        newViewWindowEvent["vcName"] = vcName as AnyObject
        newViewWindowEvent["viewWindowID"] = viewWindowID as AnyObject
        newViewWindowEvent["viewWindowEvent"] = "segued to" as AnyObject
        newViewWindowEvent["viewWindowTimestamp"] = Date() as AnyObject
        newViewWindowEvent.saveInBackground(block: (
            {(success: Bool, error: Error?) -> Void in
                if (!success) {
                    print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                    newViewWindowEvent.saveEventually()
                }
        })
        )
        
        var viewWindowDict = [String: String]()
        viewWindowDict["vcName"] = vcName
        viewWindowDict["viewWindowID"] = viewWindowID
        appDel.set(viewWindowDict, forKey: viewWindowDictKey)
        appDel.synchronize()
        
        //if view reappears (non-segue, e.g. if user navigates back), reset timers
        
        intervalData = 29
        intervalUI = 31
        sendLocalNotification_targetCount = 0
        
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        nearbyRunnersTimer_data.invalidate()
        nearbyRunnersTimer_UI.invalidate()
        
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(intervalData), target: self, selector: #selector(DashboardViewController.monitorUser_data), userInfo: nil, repeats: true)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(intervalUI), target: self, selector: #selector(DashboardViewController.monitorUser_UI), userInfo: nil, repeats: true)
        
        nearbyRunnersTimer_data = Timer.scheduledTimer(timeInterval: Double(intervalData), target: self, selector: #selector(DashboardViewController.updateNearbyRunners_data), userInfo: nil, repeats: true)
        nearbyRunnersTimer_UI = Timer.scheduledTimer(timeInterval: Double(intervalUI), target: self, selector: #selector(DashboardViewController.updateNearbyRunners_UI), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        print("viewWillDisappear")
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        nearbyRunnersTimer_data.invalidate()
        nearbyRunnersTimer_UI.invalidate()
        
        let newViewWindow = PFObject(className: "ViewWindows")
        newViewWindow["userID"] = PFUser.current()!.objectId as AnyObject
        newViewWindow["vcName"] = vcName as AnyObject
        newViewWindow["viewWindowID"] = viewWindowID as AnyObject
        newViewWindow["viewWindowEvent"] = "segued away" as AnyObject
        newViewWindow["viewWindowTimestamp"] = Date() as AnyObject
        newViewWindow.saveInBackground(block: (
            {(success: Bool, error: Error?) -> Void in
                if (!success) {
                    print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                    newViewWindow.saveEventually()
                }
        })
        )
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    
        // hide all runner information
        clearTargetDashboard()
        clearGeneralDashboard()
        
        isSpectatorIdle = true
        didSpectatorCheerRecently = false
        areTargetRunnersNearby = false
        areRunnersNearby = false
        
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        verifiedDelivery = VerifiedDelivery()
        intervalData = 29
        intervalUI = 31
        lastGeneralRunnerNotificationTime = NSDate()
        timeSinceLastNotification = 0.0
        sendLocalNotification_targetCount = 0
        
        
        // initialize mapview
        mapView.delegate = self
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
        let region = MKCoordinateRegionMakeWithDistance((self.optimizedRunners.locationMgr.location?.coordinate)!, 25*1000, 25*1000)  // 25km -- demo
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        // check once for any nearby runners on view load
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(DashboardViewController.monitorUser_data), userInfo: nil, repeats: false)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: 6, target: self, selector: #selector(DashboardViewController.monitorUser_UI), userInfo: nil, repeats: false)
        
        nearbyRunnersTimer_data = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(DashboardViewController.updateNearbyRunners_data), userInfo: nil, repeats: false)
        nearbyRunnersTimer_UI = Timer.scheduledTimer(timeInterval: 6, target: self, selector: #selector(DashboardViewController.updateNearbyRunners_UI), userInfo: nil, repeats: false)
        
        
        // every interval, log spectator loc and update nearby runners
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(intervalData), target: self, selector: #selector(DashboardViewController.monitorUser_data), userInfo: nil, repeats: true)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(intervalUI), target: self, selector: #selector(DashboardViewController.monitorUser_UI), userInfo: nil, repeats: true)
        
        nearbyRunnersTimer_data = Timer.scheduledTimer(timeInterval: Double(intervalData), target: self, selector: #selector(DashboardViewController.updateNearbyRunners_data), userInfo: nil, repeats: true)
        nearbyRunnersTimer_UI = Timer.scheduledTimer(timeInterval: Double(intervalUI), target: self, selector: #selector(DashboardViewController.updateNearbyRunners_UI), userInfo: nil, repeats: true)
        
    }
    
    func monitorUser_data() {
        
        DispatchQueue.global(qos: .utility).async {
            //start spectator tracker
            self.spectatorMonitor.monitorUserLocation()
            self.spectatorMonitor.updateUserLocation()
            self.spectatorMonitor.updateUserPath(self.intervalData)
        }
    }
    
    func monitorUser_UI() {
        
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .background {
                print("app status: \(UIApplication.shared.applicationState)")
                
                self.spectatorMonitor.enableBackgroundLoc()
            }
        }
    }
    
    func updateNearbyRunners_data() {
        
        // checkProximityZone for runners at the race
        DispatchQueue.main.async {
            self.nearbyRunners = NearbyRunners()
        }
        
        DispatchQueue.global(qos: .utility).async {
            self.nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
                
                // if there are runners at the race, update their info
                // if there are no runners, set nearbyRunner state vars
                if ((runnerLocations?.isEmpty) == false) {
                    
                    self.runnerLocations = runnerLocations!
                    self.updateRunnerProfiles(runnerLocations!) // update any profile info not yet stored
                    self.updateRunnerAffinities(runnerLocations!) // update affinities (my runner vs other runners) for each runner
                    self.updateRunnerETAs(runnerLocations!) // update latest ETA of each runner
                    self.updateRunnerCheers(runnerLocations!) // update latest number of cheers each runner received
                }
                
                self.updateNearbyRunnerOpportunities(self.runnerLocations) // now that we have all the nearby runners and their data, update opportunities lists
            }
        }
        
    }
    
    func updateNearbyRunners_UI() {
        DispatchQueue.main.async {
            // if there are no runners nearby, hide all runner placeholders
            self.updateNearbyRunnerStatus() // update nearby runner state variables
            self.updateIdleTime() // update idle time state variables
            
            if !self.areRunnersNearby && !self.areTargetRunnersNearby {
                self.clearTargetDashboard()
                self.clearGeneralDashboard()
            }
            
            else {
                self.updateGeneralRunnerStatus()
                // if R* was already set, update its labels
                if self.targetRunner.username != nil {
                    self.updateTargetRunnerStatus(self.targetRunner)
                }
            }
        }
    }

    func updateNearbyRunnerOpportunities(_ runnerLocations: [PFUser: PFGeoPoint]) {
        // add nearby runners to R* and R opportunity lists
        
        print("updateNearbyRunnerOpps: runnerLocations are \(runnerLocations)")
        
        var nearbyRunnersDisplayed: [PFUser] = []
        self.nearbyGeneralRunners = [:]
        self.nearbyTargetRunners = [:]
        
        // handle runners based on affinity and distance
        if !runnerLocations.isEmpty {
            for (runner, runnerLoc) in runnerLocations {
                
                // calculate the distance between spectator and a runner
                let runnerCLLoc = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                let dist = runnerCLLoc.distance(from: self.optimizedRunners.locationMgr.location!)
                print(runner.username!, dist)
                
                // for each runner, determine if target or general, and handle separately based on distance
                for affinity in self.runnerAffinities {
                    if runner == affinity.0 {
                        
                        // target runner
                        if affinity.1 == 10 {
                            DispatchQueue.main.async {
                                // reset R* map
                                self.removeRunnerPins()
                                self.addRunnerPin(runner, runnerType: 1)
                            }
                            
                            nearbyRunnersDisplayed.append(runner)
                            self.nearbyTargetRunners[runner] = false
                            
                            if dist <= 300 { // if runner is less than 1.5k away (5/10k: 1000m) (demo: 300m)
                                self.nearbyRunnersTimer_data.invalidate() // TODO: think about ramping up notification timers too
                                self.nearbyRunnersTimer_UI.invalidate() // TODO: are we resetting these back to the longer interval once the runner has passed by?
                                self.nearbyRunnersTimer_data = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(DashboardViewController.updateNearbyRunners_data), userInfo: nil, repeats: true) // ramp up monitoring
                                self.nearbyRunnersTimer_UI = Timer.scheduledTimer(timeInterval: 6, target: self, selector: #selector(DashboardViewController.updateNearbyRunners_UI), userInfo: nil, repeats: true) // ramp up monitoring
                                self.targetRunnerTrack.isEnabled = true
                                self.nearbyTargetRunners[runner] = true
                            }
                        }
                            
                            // not target runner
                        else if affinity.1 != 10 {
                            if dist <= 300 { //if runner is less than 1k away (5/10k: 700m) (demo: 300m)
                                self.nearbyGeneralRunners[runner] = true
                                nearbyRunnersDisplayed.append(runner)
                            }
                        }
                    }
                }
            }
            
            self.optimizedRunners.saveDisplayedRunners(nearbyRunnersDisplayed)
        }
    }
    
    func updateNearbyRunnerStatus() {
        // update state of nearby R and R* runners
        
        print("updateNearbyRunnerStatus")
        
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
            self.targetRunnerName.text = "no runner"
        }
    }
    
    func updateIdleTime() {
        
        print("updateIdleTime")
        
        if (self.areRunnersNearby && self.areTargetRunnersNearby) || self.areTargetRunnersNearby {
            let ETA = getRunnerETA(self.targetRunner) // TODO: make sure passing target runner is safe (not empty, "right" target runner aka the one displayed or pass all target runners and loop through them later
            
            verifiedDelivery = VerifiedDelivery()
            
            DispatchQueue.global(qos: .utility).async {
                self.verifiedDelivery.didSpectatorCheerRecently(self.targetRunner) { (didCheerRecently) -> Void in
                    
                    self.didSpectatorCheerRecently = didCheerRecently
                    
                    if ETA <= 1 && !self.didSpectatorCheerRecently { //if they are nearby and I did not just cheer for them
                        self.isSpectatorIdle = false
                    }
                    else if ETA <= 1 && self.didSpectatorCheerRecently  {
                        self.isSpectatorIdle = true
                    }
                    else if ETA > 1 {
                        self.isSpectatorIdle = true
                    }
                }
            }
        }
        
        else {
            self.isSpectatorIdle = true // if we don't detect runners, then assume they are idle
        }
        
        print("isSpectatorIdle? \(isSpectatorIdle)")
    }
    
    func updateTargetRunnerStatus(_ runner: PFUser) {
        
        // get runner's pic, name, ETA from stored nearby runners
        let targetPic = getRunnerImage(runner.objectId!, runnerProfiles: self.runnerProfiles)
        self.targetRunnerNameText = getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
        let ETA = getRunnerETA(runner)
//        let (cheers, cheersColor) = getRunnerCheers(runner)
        
        print("Target runner: \(targetRunnerNameText)")
        print("ETA for target: \(ETA)")
        
        targetRunnerPic.image = targetPic
        targetRunnerName.text = self.targetRunnerNameText
        
        if !isSpectatorIdle {
            
            // if spectator is not idle
            self.targetRunnerETA.text = "<1 mi away"
            self.targetRunnerETA.textColor = self.redLabel.textColor
            self.targetRunnerTrack.isHidden = false
            self.targetRunnerTrack.backgroundColor = self.redLabel.textColor
            
            self.nonIdleTimeBanner.isHidden = false
            
            let newNotification = PFObject(className: "SpectatorNotifications")
            let notificationID = arc4random_uniform(10000000)
            newNotification["spectator"] = PFUser.current()?.objectId
            newNotification["source"] = "dash_nonIdleBannerShown"
            newNotification["event"] = "R*==close && did not just cheer = non-idle"
            newNotification["notificationID"] = notificationID
            newNotification["sentNotification"] = true
            newNotification["sentNotificationTimestamp"] = Date() as AnyObject
            newNotification.saveInBackground()
            
            // if there are any targetRunners nearby, notify spectator
            for (runner, isNearby) in nearbyTargetRunners {
                
                if isNearby == true {

                    let name =  getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
                    if UIApplication.shared.applicationState == .background {
                        
                        let localNotification = UILocalNotification()
                        let notificationID = arc4random_uniform(10000000)
                        
                        var spectatorInfo = [String: AnyObject]()
                        
                        spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
                        spectatorInfo["source"] = "dash_targetRunnerNotification" as AnyObject
                        spectatorInfo["notificationID"] = notificationID as AnyObject
                        spectatorInfo["receivedNotification"] = true as AnyObject
                        spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
                        
                        localNotification.alertBody =  name + " is nearby, view their status!"
                        localNotification.soundName = UILocalNotificationDefaultSoundName
                        localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                        
                        spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
                        localNotification.userInfo = spectatorInfo
                        
                        sendLocalNotification_targetCount += 1
                        if sendLocalNotification_targetCount<=3 {
                            
                            UIApplication.shared.presentLocalNotificationNow(localNotification)
                            
                            let newNotification = PFObject(className: "SpectatorNotifications")
                            newNotification["spectator"] = localNotification.userInfo!["spectator"]
                            newNotification["source"] = localNotification.userInfo!["source"]
                            newNotification["notificationID"] = notificationID
                            newNotification["sentNotification"] = true
                            newNotification["sentNotificationTimestamp"] = Date() as AnyObject
                            newNotification["unreadNotificationCount"] = localNotification.userInfo!["unreadNotificationCount"]
                            newNotification.saveInBackground()
                        }
                    }
                }
            }
        }
        
        else if isSpectatorIdle && !didSpectatorCheerRecently {
            
            // if spectator is idle and they did not just cheer (aka target runner is far off)
            self.targetRunnerETA.text = String(format: "%d mi away", ETA)
            self.targetRunnerETA.textColor = self.targetRunnerName.textColor
            self.targetRunnerTrack.backgroundColor = self.general1RunnerTrack.backgroundColor
            
            self.nonIdleTimeBanner.isHidden = true
            
            let newNotification = PFObject(className: "SpectatorNotifications")
            let notificationID = arc4random_uniform(10000000)
            newNotification["spectator"] = PFUser.current()?.objectId
            newNotification["source"] = "dash_nonIdleBannerHidden"
            newNotification["event"] = "R*==far = idle"
            newNotification["notificationID"] = notificationID
            newNotification["sentNotification"] = true
            newNotification["sentNotificationTimestamp"] = Date() as AnyObject
            newNotification.saveInBackground()
            
        }
            
        else if isSpectatorIdle && didSpectatorCheerRecently {
            
            // if spectator is idle and cheered for this target runner just now
            self.targetRunnerETA.text = "just ran by"
            self.targetRunnerETA.textColor = self.targetRunnerName.textColor
            self.targetRunnerTrack.backgroundColor = self.general1RunnerTrack.backgroundColor
            self.nonIdleTimeBanner.isHidden = true
            
            let newNotification = PFObject(className: "SpectatorNotifications")
            let notificationID = arc4random_uniform(10000000)
            newNotification["spectator"] = PFUser.current()?.objectId
            newNotification["source"] = "dash_nonIdleBannerHidden"
            newNotification["event"] = "R*==close && did just cheer = idle"
            newNotification["notificationID"] = notificationID
            newNotification["sentNotification"] = true
            newNotification["sentNotificationTimestamp"] = Date() as AnyObject
            newNotification.saveInBackground()
            
        }
        
        targetRunnerName.isHidden = false
        targetRunnerETA.isHidden = false
        targetRunnerPic.isHidden = false
    }
    
    func updateGeneralRunnerStatus() {
        
        var generalRunners = self.nearbyGeneralRunners
        print("generalRunners in dashboardVC: \(generalRunners)")
        
        if !generalRunners.isEmpty {
            
            if isSpectatorIdle {
                
                //IDLE + OPPORTUNITY
                self.general1RunnerETA.textColor = self.redLabel.textColor
                self.general2RunnerETA.textColor = self.redLabel.textColor
                self.general3RunnerETA.textColor = self.redLabel.textColor
                self.idleTimeBanner.isHidden = false
                
                let newNotification = PFObject(className: "SpectatorNotifications")
                let notificationID = arc4random_uniform(10000000)
                newNotification["spectator"] = PFUser.current()?.objectId
                newNotification["source"] = "dash_idleBannerShown_opportunity_idle"
                newNotification["notificationID"] = notificationID
                newNotification["sentNotification"] = true
                newNotification["sentNotificationTimestamp"] = Date() as AnyObject
                newNotification.saveInBackground()
            }
            
            else if !isSpectatorIdle {
                
                //OPPORTUNITIES BUT NOT IDLE
                self.disableGeneralRunners()
                
            }
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
    
    func notifyForGeneralRunners() {
        
        if UIApplication.shared.applicationState == .background {
            
            print("time since last R notification: \(timeSinceLastNotification)s")
            
            if isSpectatorIdle {
                if timeSinceLastNotification < Double(intervalData) {
                    if self.targetRunner.username != nil {
                        let ETA = String(getRunnerETA(self.targetRunner))
                        let name = getRunnerName(self.targetRunner.objectId!, runnerProfiles: self.runnerProfiles)
                        sendLocalNotification_general_targetCheckin(name, ETA)
                    }
                }
                    
                else {
                    let now = NSDate()
                    if timeSinceLastNotification != 0 {
                        //NOTE: This value is actually going 30s ahead of what's used in the above if statement
                        timeSinceLastNotification = now.timeIntervalSince(lastGeneralRunnerNotificationTime as Date) + 2
                    }
                    
                    if timeSinceLastNotification >= 60*1 { //demo: 60*1, regularly = 60*10
                        if self.targetRunner.username != nil {
                            let ETA = String(getRunnerETA(self.targetRunner))
                            let name = getRunnerName(self.targetRunner.objectId!, runnerProfiles: self.runnerProfiles)
                            sendLocalNotification_general_targetCheckin(name, ETA)
                        }
                    }
                }
            }
        }
    }
    
    func sendLocalNotification_general_targetCheckin(_ name: String, _ ETA: String) {
        
        let localNotification = UILocalNotification()
        let notificationID = arc4random_uniform(10000000)
        
        var spectatorInfo = [String: AnyObject]()
        spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
        spectatorInfo["source"] = "dash_generalRunnerNotification_Target" as AnyObject
        spectatorInfo["notificationID"] = notificationID as AnyObject
        spectatorInfo["receivedNotification"] = true as AnyObject
        spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
        
        if (Int(ETA)!)>=1 {
            localNotification.alertBody = name + " is " + ETA + "mi out and doing well, but some nearby runners need your help! Cheer for them while you wait!"
        }
        else {
            localNotification.alertBody = name + " just passed by and is doing well, but some nearby runners need your help! Cheer for them while you wait!"
        }
        
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        
        spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
        localNotification.userInfo = spectatorInfo
        
        let newNotification = PFObject(className: "SpectatorNotifications")
        newNotification["spectator"] = localNotification.userInfo!["spectator"]
        newNotification["source"] = localNotification.userInfo!["source"]
        newNotification["favRunner"] = name
        newNotification["favRunnerStatus"] = ETA
        newNotification["notificationID"] = notificationID
        newNotification["sentNotification"] = true
        newNotification["sentNotificationTimestamp"] = Date() as AnyObject
        newNotification["unreadNotificationCount"] = localNotification.userInfo!["unreadNotificationCount"]
        newNotification.saveInBackground()
        
        UIApplication.shared.presentLocalNotificationNow(localNotification)
        
        let now = NSDate()
        lastGeneralRunnerNotificationTime = now
        
        if timeSinceLastNotification == 0 {
            timeSinceLastNotification = Double(intervalData)
        }
    }
    
    // get the name and picture for each runner in runnerLocations, store to runnerProfiles
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
    
    // get the affinities for each runner
    func updateRunnerAffinities(_ runnerLocations: [PFUser: PFGeoPoint]) {
        self.optimizedRunners.considerAffinity(runnerLocations, result: { (affinities) -> Void in
            self.runnerAffinities = affinities
            print("affinities: \(self.runnerAffinities)")
        })
    }
    
    // get the ETAs for each runner
    func updateRunnerETAs(_ runnerLocations: [PFUser: PFGeoPoint]) {
        self.optimizedRunners.considerConvenience(runnerLocations, result: { (conveniences) -> Void in
            self.runnerETAs = conveniences
            print("ETAs: \(self.runnerETAs)")
        })
    }
    
    // get the cheer counts for each runner
    func updateRunnerCheers(_ runnerLocations: [PFUser: PFGeoPoint]) {
        self.optimizedRunners.considerNeed(runnerLocations, result: { (needs) -> Void in
            self.runnerCheers = needs
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
    
    // get a runner's ETA
    func getRunnerETA(_ runner: PFUser) -> Int{
        
        var ETA: Int = Int()
        
        for user in self.runnerETAs {
            if runner.objectId  == user.0.objectId {
                ETA = user.1
                print("ETA in getETA: \(String(describing: ETA))")
            }
        }
        return ETA
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
    
    func clearTargetDashboard() {
        //hide all target runner labels + banners
        print("clearing target from dash")
        targetRunnerPic.isHidden = true
        targetRunnerName.isHidden = false //NOTE: loading label when no runner
        targetRunnerETA.isHidden = true
        targetRunnerTrack.isHidden = true
        
        nonIdleTimeBanner.isHidden = true
        
        // reset R* map
        removeRunnerPins()
    }
    
    func clearGeneralDashboard() {
        //hide all general runner labels + banners
        print("clearing general from dash")
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
        
        //NON-IDLE
        idleTimeBanner.isHidden = true
        
        let newNotification = PFObject(className: "SpectatorNotifications")
        let notificationID = arc4random_uniform(10000000)
        newNotification["spectator"] = PFUser.current()?.objectId
        newNotification["source"] = "dash_idleBannerHidden_opportunity_nonIdle"
        newNotification["notificationID"] = notificationID
        newNotification["sentNotification"] = true
        newNotification["sentNotificationTimestamp"] = Date() as AnyObject
        newNotification.saveInBackground()
        
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
                print("ERROR: unable to get runner - dashvc")
            }
            
            updateTargetRunnerStatus(targetRunner)
        }
    }
    
    func addRunnerPin(_ runner: PFUser, runnerType: Int) {
        
        if self.targetRunner.username == nil {
            self.targetRunner = runner
        }
        
        var runnerLoc = runnerLocations[runner]
        let name = self.getRunnerName(runner.objectId!, runnerProfiles: self.runnerProfiles)
        let coordinate = CLLocationCoordinate2DMake((runnerLoc?.latitude)!, (runnerLoc?.longitude)!)
        let title = name
        let runnerObjID = runner.objectId
        let type = RunnerType(rawValue: runnerType) //type would be 0 if any runner and 1 if it's my runner
        let annotation = PickRunnerAnnotation(coordinate: coordinate, title: title, type: type!, runnerObjID: runnerObjID!)
        self.mapView.addAnnotation(annotation)
    }
    
    func removeRunnerPins() {
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        print("annotationsToRemove \(annotationsToRemove)")
        mapView.removeAnnotations(annotationsToRemove)
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
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        nearbyRunnersTimer_data.invalidate()
        nearbyRunnersTimer_UI.invalidate()
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
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        nearbyRunnersTimer_data.invalidate()
        nearbyRunnersTimer_UI.invalidate()
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
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        nearbyRunnersTimer_data.invalidate()
        nearbyRunnersTimer_UI.invalidate()
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
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        nearbyRunnersTimer_data.invalidate()
        nearbyRunnersTimer_UI.invalidate()
        performSegue(withIdentifier: "trackRunner", sender: nil)
    }
}
