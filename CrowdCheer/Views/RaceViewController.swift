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
    var cheererMonitor: CheererMonitor = CheererMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
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
        
        
        //initialize mapview
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "monitorUser", userInfo: nil, repeats: true)
        self.nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "updateNearbyRunners", userInfo: nil, repeats: true)
        
    }
    
    func monitorUser() {
        
        //start cheerer tracker
        self.cheererMonitor.monitorUserLocation()
        self.cheererMonitor.updateUserPath()
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState))")
            
            self.cheererMonitor.enableBackgroundLoc()
        }
    }
    
    
    func updateNearbyRunners() {
        //every x seconds, clear map, update array of nearby runners and pin those runners
        
        let annotationsToRemove = self.mapView.annotations.filter { $0 !== self.mapView.userLocation }
        self.mapView.removeAnnotations(annotationsToRemove)
        
        self.nearbyRunners = NearbyRunners()
        self.nearbyRunners.checkCheerZone(){ (runnerLocations) -> Void in
            
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
        
        self.selectedRunners = SelectedRunners()
        self.selectedRunners.selectRunner(self.runner)
        self.userMonitorTimer.invalidate()
        self.nearbyRunnersTimer.invalidate()
    }
}

