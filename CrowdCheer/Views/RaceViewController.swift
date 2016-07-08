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
        nearbyRunnersNotifyTimer = NSTimer.scheduledTimerWithTimeInterval(180.0, target: self, selector: #selector(RaceViewController.sendLocalNotification), userInfo: nil, repeats: true)
        
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
        
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            
            if ((runnerLocations?.isEmpty) == true) {
                self.areRunnersNearby = false
            }
            else {
                self.areRunnersNearby = true
            }
            
            
            
            self.optimizedRunners.considerAffinity(runnerLocations!) { (affinities) -> Void in
                print("affinities \(affinities)")
                
                for (runner, runnerLoc) in runnerLocations! {
                    
                    for affinity in affinities {
                        if runner == affinity.0 {
                            let runnerLastLoc = CLLocationCoordinate2DMake(runnerLoc.latitude, runnerLoc.longitude)
                            self.addRunnerPin(runner, runnerLoc: runnerLastLoc)
                        }
                    }
                }
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
    
    func addRunnerPin(runner: PFUser, runnerLoc: CLLocationCoordinate2D) {
        
        let name = runner.valueForKey("name")
        let coordinate = runnerLoc
        let title = (name as? String)
        let runnerObjID = runner.objectId
        let type = RunnerType(rawValue: 0) //type would be 1 if it's my runner
        let annotation = PickRunnerAnnotation(coordinate: coordinate, title: title!, type: type!, runnerObjID: runnerObjID)
        mapView.addAnnotation(annotation)
    }
    
    func sendLocalNotification() {
        
        print("bool from identify \(nearbyRunners.areUsersNearby)")
        print("bool from VC \(areRunnersNearby)")
        if areRunnersNearby == true {
            let localNotification = UILocalNotification()
            localNotification.alertBody = "Cheer for runners near you!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
            
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        }
            
        else {
            print("local notification: no runners nearby")
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

