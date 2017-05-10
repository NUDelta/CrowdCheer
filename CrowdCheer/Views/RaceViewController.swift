//
//  RaceViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
// Copyright © 2015 Delta Lab. All rights reserved.


import UIKit
import Foundation
import MapKit
import Parse

class RaceViewController: UIViewController, MKMapViewDelegate {
    
    var runner: PFUser = PFUser()
    var runnerPic: UIImage = UIImage()
    var runnerName: String = ""
    var runnerBib: String = ""
    var runnerLastLoc = CLLocationCoordinate2D()
    
    var userMonitorTimer: Timer = Timer()
    var nearbyRunnersTimer: Timer = Timer()
    var nearbyGeneralRunnersTimer: Timer = Timer()
    var targetRunnerTrackingStatus = [String : Bool]()
    var areTargetRunnersNearby: Bool = Bool()
    var targetRunnerName: String = ""
    var areRunnersNearby: Bool = Bool()
    var interval: Int = Int()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    @IBOutlet weak var home: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var runnerLabel: UILabel!
    @IBOutlet weak var cheer: UIButton!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        cheer.setTitleColor(UIColor.gray, for: UIControlState.disabled)
        cheer.isEnabled = false
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
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
        
        updateNearbyRunners()
        
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RaceViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RaceViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        nearbyGeneralRunnersTimer = Timer.scheduledTimer(timeInterval: 60*5, target: self, selector: #selector(RaceViewController.sendLocalNotification_any), userInfo: nil, repeats: true)
        nearbyTargetRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RaceViewController.sendLocalNotification_target), userInfo: nil, repeats: true)

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
        //every x seconds, clear map, update array of nearby runners and pin those runners
        
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations(annotationsToRemove)
        var runnerCount: [PFUser] = []
        
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in

            //R+R* Condition
            self.optimizedRunners.considerAffinity(runnerLocations!) { (affinities) -> Void in
                print("affinities \(affinities)")
                
                for (runner, runnerLoc) in runnerLocations! {
                    
                    let runnerLastLoc = CLLocationCoordinate2DMake(runnerLoc.latitude, runnerLoc.longitude)
                    let runnerCoord = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                    let dist = runnerCoord.distance(from: self.optimizedRunners.locationMgr.location!)
                    print(runner.username!, dist)
                    
                    for affinity in affinities {
                        
                        var isTargetRunnerNear = false
                        if runner == affinity.0 {
                            //Goal: Show target runners throughout the race
                            if dist > 2000 { //if runner is more than 2km away (demo: 400)
                                if affinity.1 == 10 { //if target runner, add them to the map
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 1)
                                    self.targetRunnerTrackingStatus[runner.objectId!] = true
                                    runnerCount.append(runner)
                                }
                                else if affinity.1 != 10 { //if general runner, don't add them yet
                                    //do nothing
                                }
                            }
                            
                            //Goal: Show all runners near me, including target runners
                            else if dist > 500 && dist <= 2000 { //if runner is between 500m-2km away (demo: 200-400)
                                if affinity.1 == 10 { //if target runner, add them to the map
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 1)
                                    self.targetRunnerTrackingStatus[runner.objectId!] = true
                                    runnerCount.append(runner)
                                }
                                else if affinity.1 != 10 { //if general runner, also add them to the map
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 0)
                                    runnerCount.append(runner)
                                    self.areRunnersNearby = true
                                }
                            }
                                
                            //Goal: If target runner is close, only show them. If not, then continue to show all runners
                            else if dist <= 500 { //if runner is less than 500m away (demo: 200)
                                if affinity.1 == 10 { //if target runner, add them to the map & notify
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 1)
                                    self.targetRunnerTrackingStatus[runner.objectId!] = true
                                    runnerCount.append(runner)
                                    let name = runner.value(forKey: "name") as! String
                                    self.areTargetRunnersNearby = true
                                    self.targetRunnerName = name
                                    isTargetRunnerNear = true
                                }
                                else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                    if !isTargetRunnerNear {
                                        self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 0)
                                        runnerCount.append(runner)
                                        self.areRunnersNearby = true
                                    }
                                }
                            }
                        }
                    }
                }
                self.targetRunnerTrackingStatus = self.optimizedRunners.targetRunners
                self.optimizedRunners.saveDisplayedRunners(runnerCount)
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
    
    func addRunnerPin(_ runner: PFUser, runnerLoc: CLLocationCoordinate2D, runnerType: Int) {
        
        let name = runner.value(forKey: "name")
        let coordinate = runnerLoc
        let title = (name as? String)
        let runnerObjID = runner.objectId
        let type = RunnerType(rawValue: runnerType) //type would be 0 if any runner and 1 if it's my runner
        let annotation = PickRunnerAnnotation(coordinate: coordinate, title: title!, type: type!, runnerObjID: runnerObjID!)
        mapView.addAnnotation(annotation)
    }
    
    func sendLocalNotification_any() {
        if areRunnersNearby == true {
            
            if UIApplication.shared.applicationState == .background {
                let localNotification = UILocalNotification()
                localNotification.alertBody = "Cheer for runners near you!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                
                UIApplication.shared.presentLocalNotificationNow(localNotification)
            }
        }
            
        else {
            print("local notification: no runners nearby")
        }
    }
    
    func sendLocalNotification_target() {
        
        let name = targetRunnerName
        
        if areTargetRunnersNearby == true {
            
            if UIApplication.shared.applicationState == .background {
                
                let localNotification = UILocalNotification()
                localNotification.alertBody =  name + " is near you, get ready to cheer!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
                
                UIApplication.shared.presentLocalNotificationNow(localNotification)
            }
                
            else if UIApplication.shared.applicationState == .active {
                
                let alertTitle = name + " is nearby!"
                let alertController = UIAlertController(title: alertTitle, message: "Get ready to cheer!", preferredStyle: UIAlertControllerStyle.alert)
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
            
            cheer.isEnabled = true
            let ann = view.annotation as! PickRunnerAnnotation
            let runnerObjID = ann.runnerObjID
            var runnerDescription: String = ""
            do {
                runner = try PFQuery.getUserObject(withId: runnerObjID!)
            }
            catch {
                print("ERROR: unable to get runner")
            }
            let runnerName = (runner.value(forKey: "name"))!
            print("Selected runner: \(runnerName)")
            runnerDescription = String(describing: runnerName) + " needs help!"
            runnerLabel.text = runnerDescription
        }
    }

    
    @IBAction func cheer(_ sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        let source = "racemap"
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(runner, source) { (cheerSaved) -> Void in

            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        performSegue(withIdentifier: "trackRunner", sender: nil)
    }
    
    @IBAction func home(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RoleViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}

