//
//  RunViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/7/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import MapKit
import Parse

class RunViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationMgr: CLLocationManager = CLLocationManager()
    var runner: PFUser = PFUser()
    var userMonitorTimer: NSTimer = NSTimer()
    var nearbySpectatorsTimer: NSTimer = NSTimer()
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationMgr = CLLocationManager()
        runnerMonitor = RunnerMonitor()
        areSpectatorsNearby = false
        interval = 30
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        //initialize map
        //update the runner profile info
        //every 3 seconds, update the distance label and map with the runner's location
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        congrats.hidden = true
        resume.hidden = true
        pause.enabled = false
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(RunViewController.monitorUser), userInfo: nil, repeats: true)
        nearbySpectatorsTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector: #selector(RunViewController.updateNearbySpectators), userInfo: nil, repeats: true)
        
        
    }
    
    func monitorUser() {
        
        print("monitoring runner...")
        
        //start runner monitor
        runnerMonitor.monitorUserLocation()
        runnerMonitor.updateUserPath(interval)
        runnerMonitor.updateUserLocation()
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState))")
            
            runnerMonitor.enableBackgroundLoc()
        }
        
        distance.text = "Distance: " + String(format: " %.02f", runnerMonitor.metersToMiles(runnerMonitor.distance)) + "mi"
        let timeString = runnerMonitor.stringFromSeconds(runnerMonitor.duration)
        time.text = "Time: " + timeString + " s"
        pace.text = "Pace: " + (runnerMonitor.pace as String)
        
        if (locationMgr.location!.coordinate.latitude == 0.0 && locationMgr.location!.coordinate.longitude == 0.0) {  //NOTE: nil here
            print("skipping coordinate")
        }
        else {
            runnerPath.append((locationMgr.location?.coordinate)!)
        }
        drawPath()
    }
    
    func updateNearbySpectators() {
        //every x seconds, update array of nearby spectators and change location frequency accordingly
        
        nearbySpectators = NearbySpectators()
        nearbySpectators.checkProximityZone(){ (spectatorLocations) -> Void in
            
            if ((spectatorLocations?.isEmpty) == true) {
                self.areSpectatorsNearby = false
            }
            else {
                self.areSpectatorsNearby = true
                self.userMonitorTimer.invalidate()
                self.interval = 3
                self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(self.interval), target: self, selector: #selector(RunViewController.monitorUser), userInfo: nil, repeats: true)
            }
        }
    }
    
    func drawPath() {
        
        if(runnerPath.count > 1) {
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
        congrats.hidden = false
    }
    
    @IBAction func pause(sender: UIButton) {
        //suspend runner monitor when you hit pause
        
        userMonitorTimer.invalidate()
        pause.hidden = true
        resume.hidden = false
    }
    
    @IBAction func resume(sender: UIButton) {
        //resume runner monitor when you hit resume
        
        userMonitorTimer.fire()
        pause.hidden = false
        resume.hidden = true
    }
}