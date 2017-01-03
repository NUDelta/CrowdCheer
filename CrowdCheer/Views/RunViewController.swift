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
    var userMonitorTimer: NSTimer = NSTimer()
    var startDate: NSDate = NSDate()
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
        let startLine = CLLocationCoordinate2DMake(42.057102, -87.676943) //ford
        let startRegion = runnerMonitor.createStartRegion(startLine)
        runnerMonitor.startMonitoringRegion(startRegion)
        
        
        areSpectatorsNearby = false
        interval = 1
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        //initialize map
        //update the runner profile info
        //every 3 seconds, update the distance label and map with the runner's location if they are within the start region or have exited
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        resume.hidden = true
        pause.enabled = true
        
        //hide labels & buttons until tracking starts
        congrats.text = "Tracking starts automatically."
        distance.hidden = true
        time.hidden = true
        pace.hidden = true
        pause.hidden = true
        stop.hidden = true
        
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        userMonitorTimer.invalidate()
    }
    
    func monitorUserLoop() {
        
        
        if (runnerMonitor.startRegionState == "inside" || runnerMonitor.startRegionState == "exited" || runnerMonitor.startRegionState == "monitoring") {
            monitorUser()
            congrats.hidden = true
            distance.hidden = false
            time.hidden = false
            pace.hidden = false
            pause.hidden = false
            stop.hidden = false
        }
        
        if runnerMonitor.startRegionState == "exited" {
            resetTracking()
            congrats.hidden = true
            distance.hidden = false
            time.hidden = false
            pace.hidden = false
            pause.hidden = false
            stop.hidden = false
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
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState)")
            
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
                    self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(self.interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
                    self.nearbySpectators.locationMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
                }
            }
            else {
                self.areSpectatorsNearby = true
                self.userMonitorTimer.invalidate()
                self.interval = 3
                self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(self.interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
                self.nearbySpectators.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
            }
        }
    }
    
    func locationTrackingAlert() {
        let alertTitle = "Automatic Runner Tracking"
        let alertController = UIAlertController(title: alertTitle, message: "You're all set! We will automatically activate runner tracking when you arrive on race day.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func resetTracking() {
        print("Reset tracking")
        runnerMonitor = RunnerMonitor()
        runnerMonitor.startRegionState = "exited" //NOTE: not great to modify model from VC
        userMonitorTimer.invalidate()
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
    }
    
    func drawPath() {
        
        if(runnerPath.count > 1) {
            print("runnerPath is \(runnerPath)")
            let polyline = MKPolyline(coordinates: &runnerPath[0] , count: runnerPath.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        // render the path
        assert(overlay.isKindOfClass(MKPolyline))
        let polyLine = overlay
        let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
        polyLineRenderer.strokeColor = UIColor.blueColor()
        polyLineRenderer.lineWidth = 3.0
        
        return polyLineRenderer
        
    }

    
    @IBAction func stop(sender: UIButton) {
        //suspend runner monitor when you hit stop
        
        userMonitorTimer.invalidate()
        pause.hidden = true
        stop.hidden = true
        congrats.text = "Congrats! You did it!"
        congrats.hidden = false
    }
    
    @IBAction func pause(sender: UIButton) {
        //suspend runner monitor when you hit pause
        
        resetTracking()
        distance.text = "Distance: " + String(format: " %.02f", runnerMonitor.metersToMiles(runnerMonitor.distance)) + "mi"
        let timeString = runnerMonitor.stringFromSeconds(runnerMonitor.duration)
        time.text = "Time: " + timeString + " s"
        pace.text = "Pace: " + (runnerMonitor.pace as String)
        
    }
    
    @IBAction func resume(sender: UIButton) {
        //resume runner monitor when you hit resume
        
        userMonitorTimer.fire()
        pause.hidden = false
        resume.hidden = true
    }
}
