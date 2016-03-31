//
//  RaceViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
// Copyright © 2015 Delta Lab. All rights reserved.


import UIKit
import Foundation
import CoreLocation
import MapKit
import Parse

class RaceViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let locationMgr: CLLocationManager = CLLocationManager()
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
    var cheererMonitor: CheererMonitor = CheererMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    @IBOutlet weak var home: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var runnerLabel: UILabel!
    @IBOutlet weak var cheer: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
        self.cheer.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        self.cheer.enabled = false
        self.cheererMonitor = CheererMonitor()
        self.areRunnersNearby = false
        
        
        //initialize mapview
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(RaceViewController.monitorUser), userInfo: nil, repeats: true)
        self.nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(RaceViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        self.nearbyRunnersNotifyTimer = NSTimer.scheduledTimerWithTimeInterval(120.0, target: self, selector: #selector(RaceViewController.sendLocalNotification), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.userMonitorTimer.invalidate()
        self.nearbyRunnersTimer.invalidate()
    }
    
    func monitorUser() {
        
        //start cheerer tracker
        self.cheererMonitor.monitorUserLocation()
        self.cheererMonitor.updateUserPath()
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState)")
            
            self.cheererMonitor.enableBackgroundLoc()
        }
    }
    
    
    func updateNearbyRunners() {
        //every x seconds, clear map, update array of nearby runners and pin those runners
        
        let annotationsToRemove = self.mapView.annotations.filter { $0 !== self.mapView.userLocation }
        self.mapView.removeAnnotations(annotationsToRemove)
        
        self.nearbyRunners = NearbyRunners()
        self.nearbyRunners.checkCheerZone(){ (runnerLocations) -> Void in
            
            if ((runnerLocations?.isEmpty) == true) {
                self.areRunnersNearby = false
            }
            else {
                self.areRunnersNearby = true
            }
            
            for (runnerObj, runnerLoc) in runnerLocations! {
                
                let runner = PFQuery.getUserObjectWithId(runnerObj.objectId!)
                let runnerLastLoc = CLLocationCoordinate2DMake(runnerLoc.latitude, runnerLoc.longitude)
                self.addRunnerPin(runner, runnerLoc: runnerLastLoc)
                
            }
        }
        
    }
    
    func addRunnerPin(runner: PFUser, runnerLoc: CLLocationCoordinate2D) {
        
        let name = runner.valueForKey("name")
        let coordinate = runnerLoc
        let title = (name as? String)
        let runnerObjID = runner.objectId
        let type = RunnerType(rawValue: 0) //type would be 1 if it's my runner
        let annotation = PickRunnerAnnotation(coordinate: coordinate, title: title!, type: type!, runnerObjID: runnerObjID)
        self.mapView.addAnnotation(annotation)
    }
    
    func sendLocalNotification() {
        
        print("bool from identify \(self.nearbyRunners.areRunnersNearby)")
        print("bool from VC \(self.areRunnersNearby)")
        if self.areRunnersNearby == true {
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
            
            self.cheer.enabled = true
            let ann = view.annotation as! PickRunnerAnnotation
            let runnerObjID = ann.runnerObjID
            var runnerDescription: String = ""
            self.runner = PFQuery.getUserObjectWithId(runnerObjID)
            let runnerName = (self.runner.valueForKey("name"))!
            print("Selected runner: \(runnerName)")
            runnerDescription = String(runnerName) + " needs help!"
            self.runnerLabel.text = runnerDescription
        }
    }

    
    func mapView(mapView: MKMapView, didChangeUserTrackingMode mode: MKUserTrackingMode, animated: Bool) {
        var newMode: MKUserTrackingMode = MKUserTrackingMode.None
        if CLLocationManager.headingAvailable() {
            newMode = MKUserTrackingMode.FollowWithHeading
        }
        else {
            newMode = MKUserTrackingMode.Follow
        }
        
        if mode != newMode {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
            })
        }
    }
    
    @IBAction func cheer(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:cheerer pairing
        var isCheerSaved = true
        self.selectedRunners = SelectedRunners()
        self.selectedRunners.selectRunner(self.runner) { (cheerSaved) -> Void in

            isCheerSaved = cheerSaved
        }
        
        if isCheerSaved == true {
            self.userMonitorTimer.invalidate()
            self.nearbyRunnersTimer.invalidate()
            self.nearbyRunnersNotifyTimer.invalidate()
            self.performSegueWithIdentifier("trackRunner", sender: nil)
        }
        else {
            //do nothing
        }
        
        
    }
    
    @IBAction func home(sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("RoleViewController") as UIViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

