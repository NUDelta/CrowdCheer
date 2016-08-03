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
    var runnerPath: Array<CLLocationCoordinate2D> = []
    
    var userMonitorTimer: NSTimer = NSTimer()
    var nearbyRunnersTimer: NSTimer = NSTimer()
    var nearbyRunnersNotifyTimer: NSTimer = NSTimer()
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
        cheer.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        cheer.enabled = false
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
        areRunnersNearby = false
        interval = 30
        
        //initialize mapview
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        updateNearbyRunners()
        
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(RaceViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(RaceViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
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
        //every x seconds, clear map, update array of nearby runners and pin those runners
        
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations(annotationsToRemove)
        var runnerCount = 0
        
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
                    
                    let runnerLastLoc = CLLocationCoordinate2DMake(runnerLoc.latitude, runnerLoc.longitude)
                    let runnerCoord = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                    let dist = runnerCoord.distanceFromLocation(self.optimizedRunners.locationMgr.location!)
                    print(runner.username, dist)
                    
                    for affinity in affinities {
                        var isTargetRunnerNear = false
                        if runner == affinity.0 {
                            //Goal: Show target runners throughout the race
                            if dist > 2000 { //if runner is more than 2km away
                                if affinity.1 == 10 { //if target runner, add them to the map
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 1)
                                    runnerCount += 1
                                }
                                else if affinity.1 != 10 { //if general runner, don't add them yet
                                    //do nothing
                                }
                            }
                            
                            //Goal: Show all runners near me, including target runners
                            else if dist > 1000 && dist <= 2000 { //if runner is between 1-2km away
                                if affinity.1 == 10 { //if target runner, add them to the map
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 1)
                                    runnerCount += 1
                                }
                                else if affinity.1 != 10 { //if general runner, also add them to the map
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 0)
                                    runnerCount += 1
                                    self.sendLocalNotification_any()
                                }
                            }
                                
                            //Goal: If target runner is close, only show them. If not, then continue to show all runners
                            else if dist <= 1000 { //if runner is less than 1km away
                                if affinity.1 == 10 { //if target runner, add them to the map & notify
                                    self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 1)
                                    runnerCount += 1
                                    let name = runner.valueForKey("name") as! String
                                    self.sendLocalNotification_target(name)
                                    isTargetRunnerNear = true
                                    print("isTargetRunnerNear: \(isTargetRunnerNear)")
                                }
                                else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                    if !isTargetRunnerNear {
                                        self.addRunnerPin(runner, runnerLoc: runnerLastLoc, runnerType: 0)
                                        runnerCount += 1
                                    }
                                }
                            }
                        }
                    }
                }
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
    
    func addRunnerPin(runner: PFUser, runnerLoc: CLLocationCoordinate2D, runnerType: Int) {
        
        let name = runner.valueForKey("name")
        let coordinate = runnerLoc
        let title = (name as? String)
        let runnerObjID = runner.objectId
        let type = RunnerType(rawValue: runnerType) //type would be 0 if any runner and 1 if it's my runner
        let annotation = PickRunnerAnnotation(coordinate: coordinate, title: title!, type: type!, runnerObjID: runnerObjID)
        mapView.addAnnotation(annotation)
    }
    
    func sendLocalNotification_any() {
        
        print("bool from identify \(nearbyRunners.areUsersNearby)")
        print("bool from VC \(areRunnersNearby)")
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        else {
            let annotationView = PickRunnerAnnotationView(annotation: annotation, reuseIdentifier: "Runner")
            annotationView.canShowCallout = true
            return annotationView
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        print("\(view.annotation?.title) has been tapped")
        if (view is PickRunnerAnnotationView) {
            
            cheer.enabled = true
            let ann = view.annotation as! PickRunnerAnnotation
            let runnerObjID = ann.runnerObjID
            var runnerDescription: String = ""
            runner = PFQuery.getUserObjectWithId(runnerObjID)
            let runnerName = (runner.valueForKey("name"))!
            print("Selected runner: \(runnerName)")
            runnerDescription = String(runnerName) + " needs help!"
            runnerLabel.text = runnerDescription
        }
    }

    
    @IBAction func cheer(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:spectator pairing
        var isCheerSaved = true
        selectedRunners = SelectedRunners()
        selectedRunners.selectRunner(runner) { (cheerSaved) -> Void in

            isCheerSaved = cheerSaved
        }
        
        print("isCheerSaved? \(isCheerSaved)")
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        nearbyRunnersNotifyTimer.invalidate()
        performSegueWithIdentifier("trackRunner", sender: nil)
    }
    
    @IBAction func home(sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("RoleViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}

