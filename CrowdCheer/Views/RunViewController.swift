//
//  RunViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/7/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import MapKit
import Parse

class RunViewController: UIViewController, MKMapViewDelegate {
    
    var runner: PFUser = PFUser()
    var userMonitorTimer: Timer = Timer()
    var startDate: Date = Date()
    var startsRegionMonitoringWithinRegion: Bool = Bool()
    var runnerMonitor: RunnerMonitor = RunnerMonitor()
    var nearbySpectators: NearbySpectators = NearbySpectators()
    var areSpectatorsNearby: Bool = Bool()
    var interval: Int = Int()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var pace: UILabel!
    @IBOutlet weak var pause: UIButton!
    @IBOutlet weak var resume: UIButton!
    @IBOutlet weak var stop: UIButton!
    @IBOutlet weak var congrats: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var home: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationTrackingAlert()
        runnerMonitor = RunnerMonitor()
//        let startLine = CLLocationCoordinate2DMake(42.059182, -87.673772) //garage
//        let startLine = CLLocationCoordinate2DMake(42.057102, -87.676943) //ford
//        let startLine = CLLocationCoordinate2DMake(42.058175, -87.683502) //noyes el
//        let startLine = CLLocationCoordinate2DMake(42.051169, -87.677232) //arch
        let startLine = CLLocationCoordinate2DMake(41.964809, -87.638939) //race
        let startRegion = runnerMonitor.createStartRegion(startLine)
        runnerMonitor.startMonitoringRegion(startRegion)
        
        
        areSpectatorsNearby = false
        interval = 1
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        //initialize map
        //update the runner profile info
        //every 3 seconds, update the distance label and map with the runner's location if they are within the start region or have exited
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        resume.isHidden = true
        pause.isEnabled = true
        
        //hide labels & buttons until tracking starts
        congrats.text = "Tracking starts automatically."
        distance.isHidden = true
        time.isHidden = true
        pace.isHidden = true
        pause.isHidden = true
        stop.isHidden = true
        
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        userMonitorTimer.invalidate()
    }
    
    func monitorUserLoop() {
        
        
        if (runnerMonitor.startRegionState == "inside" || runnerMonitor.startRegionState == "exited" || runnerMonitor.startRegionState == "monitoring") {
            monitorUser()
            congrats.isHidden = true
            distance.isHidden = false
            time.isHidden = false
            pace.isHidden = false
            pause.isHidden = false
            stop.isHidden = false
        }
        
        if runnerMonitor.startRegionState == "exited" {
            resetTracking()
            congrats.isHidden = true
            distance.isHidden = false
            time.isHidden = false
            pace.isHidden = false
            pause.isHidden = false
            stop.isHidden = false
            runnerMonitor.startRegionState = "monitoring"
        }
    }
    
    func monitorUser() {
        //monitor runner
        print("monitoring runner...")
        
        //start runner monitor
        runnerMonitor.monitorUserLocation()
        runnerMonitor.updateUserPath(interval)
        runnerMonitor.updateUserLocation()
        
        //check for nearby spectators
        updateNearbySpectators()
        
        if UIApplication.shared.applicationState == .background {
            print("app status: \(UIApplication.shared.applicationState)")
            
            runnerMonitor.enableBackgroundLoc()
        }
        
        distance.text = "Distance: " + String(format: " %.02f", runnerMonitor.metersToMiles(runnerMonitor.distance)) + "mi"
        let timeString = runnerMonitor.stringFromSeconds(runnerMonitor.duration)
        time.text = "Time: " + timeString + " s"
        pace.text = "Pace: " + (runnerMonitor.pace as String)
        
        if (runnerMonitor.locationMgr.location!.coordinate.latitude == 0.0 && runnerMonitor.locationMgr.location!.coordinate.longitude == 0.0) {  //NOTE: nil here
            print("skipping coordinate")
        }
        else {
            runnerPath.append((runnerMonitor.locationMgr.location?.coordinate)!)
        }
        //        drawPath()
    }
    
    func updateNearbySpectators() {
        //every x seconds, update array of nearby spectators and change location frequency accordingly
        
        nearbySpectators = NearbySpectators()
        nearbySpectators.checkProximityZone(){ (spectatorLocations) -> Void in
            
            if ((spectatorLocations?.isEmpty) == true) {
                self.areSpectatorsNearby = false
                if self.userMonitorTimer.timeInterval < 30 {
                    self.userMonitorTimer.invalidate()
                    self.interval = 30
                    self.userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
                    self.nearbySpectators.locationMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
                }
            }
            else {
                self.areSpectatorsNearby = true
                self.userMonitorTimer.invalidate()
                self.interval = 3
                self.userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
                self.nearbySpectators.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
            }
        }
    }
    
    func locationTrackingAlert() {
        let alertTitle = "Automatic Runner Tracking"
        let alertController = UIAlertController(title: alertTitle, message: "You're all set! We will automatically activate runner tracking when you arrive on race day.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func resetTracking() {
        print("Reset tracking")
        runnerMonitor = RunnerMonitor()
        runnerMonitor.startRegionState = "exited" //NOTE: not great to modify model from VC
        userMonitorTimer.invalidate()
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
    }
    
    func drawPath() {
        
        if(runnerPath.count > 1) {
            print("runnerPath is \(runnerPath)")
            let polyline = MKPolyline(coordinates: &runnerPath[0] , count: runnerPath.count)
            mapView.add(polyline)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // render the path
        assert(overlay.isKind(of: MKPolyline.self))
        let polyLine = overlay
        let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
        polyLineRenderer.strokeColor = UIColor.blue
        polyLineRenderer.lineWidth = 3.0
        
        return polyLineRenderer
        
    }

    
    @IBAction func stop(_ sender: UIButton) {
        //suspend runner monitor when you hit stop
        
        userMonitorTimer.invalidate()
        pause.isHidden = true
        stop.isHidden = true
        congrats.text = "Congrats! You did it!"
        congrats.isHidden = false
    }
    
    @IBAction func pause(_ sender: UIButton) {
        //suspend runner monitor when you hit pause
        
        resetTracking()
        distance.text = "Distance: " + String(format: " %.02f", runnerMonitor.metersToMiles(runnerMonitor.distance)) + "mi"
        let timeString = runnerMonitor.stringFromSeconds(runnerMonitor.duration)
        time.text = "Time: " + timeString + " s"
        pace.text = "Pace: " + (runnerMonitor.pace as String)
        
    }
    
    @IBAction func resume(_ sender: UIButton) {
        //resume runner monitor when you hit resume
        
        userMonitorTimer.fire()
        pause.isHidden = false
        resume.isHidden = true
    }
}
