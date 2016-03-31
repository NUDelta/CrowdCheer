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
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var runner: PFUser = PFUser()
    var userMonitorTimer: NSTimer = NSTimer()
    var runnerMonitor: RunnerMonitor = RunnerMonitor()
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
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
        self.runnerMonitor = RunnerMonitor()
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        //initialize map
        //update the runner profile info
        //every second, update the distance label and map with the runner's location
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        
        self.congrats.hidden = true
        self.resume.hidden = true
        self.pause.hidden = true
        
        self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(RunViewController.monitorUser), userInfo: nil, repeats: true)
        
        
    }
    
    func monitorUser() {
        
        print("monitoring runner...")
        
        //start runner monitor
        self.runnerMonitor.monitorUserLocation()
        self.runnerMonitor.updateUserPath()
        self.runnerMonitor.updateUserLocation()
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState))")
            
            self.runnerMonitor.enableBackgroundLoc()
        }
        
        distance.text = "Distance: " + String(format: " %.02f", self.runnerMonitor.metersToMiles(self.runnerMonitor.distance)) + "mi"
        let timeString = self.runnerMonitor.stringFromSeconds(self.runnerMonitor.duration)
        time.text = "Time: " + timeString + " s"
        pace.text = "Pace: " + (self.runnerMonitor.pace as String)
        
        if (locationMgr.location!.coordinate.latitude == 0.0 && locationMgr.location!.coordinate.longitude == 0.0) {
            print("skipping coordinate")
        }
        else {
            self.runnerPath.append((locationMgr.location?.coordinate)!)
        }
        drawPath()
    }
    
    
    func drawPath() {
        
        if(self.runnerPath.count > 1) {
            let polyline = MKPolyline(coordinates: &self.runnerPath[0] , count: self.runnerPath.count)
            self.mapView.addOverlay(polyline)
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
        
        self.userMonitorTimer.invalidate()
        self.pause.hidden = true
        self.stop.hidden = true
        self.congrats.hidden = false
    }
    
    @IBAction func pause(sender: UIButton) {
        //suspend runner monitor when you hit pause
        
        self.userMonitorTimer.invalidate()
        self.pause.hidden = true
        self.resume.hidden = false
    }
    
    @IBAction func resume(sender: UIButton) {
        //resume runner monitor when you hit resume
        
        self.userMonitorTimer.fire()
        self.pause.hidden = false
        self.resume.hidden = true
    }
}