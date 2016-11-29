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
    var nearbySpectatorsTimer: NSTimer = NSTimer()
    var startDate: NSDate = NSDate()
    var startTimer: NSTimer = NSTimer()
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
        let startLine = CLLocationCoordinate2DMake(42.057102, -87.676943)
        let startRegion = runnerMonitor.createStartRegion(startLine)
        runnerMonitor.startMonitoringRegion(startRegion)
        
        
        areSpectatorsNearby = false
        interval = 1
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        //initialize map
        //check whether runner is in the start region or not
        //update the runner profile info
        //every 3 seconds, update the distance label and map with the runner's location
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        congrats.hidden = true
        resume.hidden = true
        pause.enabled = true
        
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(RunViewController.monitorUserLoop), userInfo: nil, repeats: true)
//        nearbySpectatorsTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: #selector(RunViewController.updateNearbySpectators), userInfo: nil, repeats: true)
        
        //reset race data when race starts
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        startDate = dateFormatter.dateFromString(startDateString)! //hardcoded race start time
//        startTimer = NSTimer.scheduledTimerWithTimeInterval(startDate.timeIntervalSinceDate(NSDate()), target: self, selector: #selector(RunViewController.resetTracking), userInfo: nil, repeats: false)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        userMonitorTimer.invalidate()
        nearbySpectatorsTimer.invalidate()
        
    }
    
    func monitorUserLoop() {
        
        
        if (runnerMonitor.startRegionState == "inside" || runnerMonitor.startRegionState == "exited") {
            monitorUser()
        }
        
        if runnerMonitor.startRegionState == "exited" {
            resetTracking()
        }
    }
    
    func monitorUser() {
        //monitor runner
        print("monitoring runner...")
        
        //start runner monitor
        runnerMonitor.monitorUserLocation()
        runnerMonitor.updateUserPath(interval)
        runnerMonitor.updateUserLocation()
        
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
                    self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(self.interval), target: self, selector: #selector(RunViewController.monitorUser), userInfo: nil, repeats: true)
                    self.nearbySpectators.locationMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
                }
            }
            else {
                self.areSpectatorsNearby = true
                self.userMonitorTimer.invalidate()
                self.interval = 3
                self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(self.interval), target: self, selector: #selector(RunViewController.monitorUser), userInfo: nil, repeats: true)
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
    
    
    func genericTestingNotification(message: String) {
        let localNotification = UILocalNotification()
        if #available(iOS 8.2, *) {
            localNotification.alertTitle = "Geofence Status"
        } else {
            // Fallback on earlier versions
        }
        localNotification.alertBody = message
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    
    func resetTracking() {
        print("Reset tracking")
        runnerMonitor = RunnerMonitor()
        userMonitorTimer.invalidate()
        nearbySpectatorsTimer.invalidate()
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(RunViewController.monitorUser), userInfo: nil, repeats: true)
//        nearbySpectatorsTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: #selector(RunViewController.updateNearbySpectators), userInfo: nil, repeats: true)
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
        nearbySpectatorsTimer.invalidate()
        pause.hidden = true
        stop.hidden = true
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
