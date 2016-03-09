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
    var myLocation = CLLocation()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var pace: UILabel!
    @IBOutlet weak var pause: UIButton!
    @IBOutlet weak var stop: UIButton!
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
        
        self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "monitorUser", userInfo: nil, repeats: true)
        
    }
    
    func monitorUser() {
        
        //start runner monitor
        self.runnerMonitor.monitorUserLocation()
        self.runnerMonitor.updateUserPath()
        self.runnerMonitor.updateUserLocation()
        
        distance.text = "Distance: " + String(format: " %.02f", self.runnerMonitor.distance) + "m"
        time.text = "Time: " + String(format: " %ld", self.runnerMonitor.duration) + " s"
        pace.text = "Pace: " + (self.runnerMonitor.pace as String)
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
    
    @IBAction func stop(sender: UIButton) {
        //suspend runner monitor when you hit stop
        
        self.userMonitorTimer.invalidate()
    }
}