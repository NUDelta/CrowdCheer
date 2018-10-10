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
    var userMonitorTimer_data: Timer = Timer()
    var userMonitorTimer_UI: Timer = Timer()
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
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var pause: UIButton!
    @IBOutlet weak var resume: UIButton!
    @IBOutlet weak var stop: UIButton!
    @IBOutlet weak var congrats: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var home: UIBarButtonItem!
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "RunVC"
    
    override func viewDidAppear(_ animated: Bool) {
        
        viewWindowID = String(arc4random_uniform(10000000))
        
        let newViewWindowEvent = PFObject(className: "ViewWindows")
        newViewWindowEvent["userID"] = PFUser.current()!.objectId as AnyObject
        newViewWindowEvent["vcName"] = vcName as AnyObject
        newViewWindowEvent["viewWindowID"] = viewWindowID as AnyObject
        newViewWindowEvent["viewWindowEvent"] = "segued to" as AnyObject
        newViewWindowEvent["viewWindowTimestamp"] = Date() as AnyObject
        newViewWindowEvent.saveInBackground(block: (
            {(success: Bool, error: Error?) -> Void in
                if (!success) {
                    print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                    newViewWindowEvent.saveEventually()
                }
        })
        )
        
        var viewWindowDict = [String: String]()
        viewWindowDict["vcName"] = vcName
        viewWindowDict["viewWindowID"] = viewWindowID
        appDel.set(viewWindowDict, forKey: viewWindowDictKey)
        appDel.synchronize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        
        let newViewWindow = PFObject(className: "ViewWindows")
        newViewWindow["userID"] = PFUser.current()!.objectId as AnyObject
        newViewWindow["vcName"] = vcName as AnyObject
        newViewWindow["viewWindowID"] = viewWindowID as AnyObject
        newViewWindow["viewWindowEvent"] = "segued away" as AnyObject
        newViewWindow["viewWindowTimestamp"] = Date() as AnyObject
        newViewWindow.saveInBackground(block: (
            {(success: Bool, error: Error?) -> Void in
                if (!success) {
                    print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                    newViewWindow.saveEventually()
                }
        })
        )
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationTrackingAlert()
        runnerMonitor = RunnerMonitor()
//        let startLine = CLLocationCoordinate2DMake(42.059182, -87.673772) //garage
//        let startLine = CLLocationCoordinate2DMake(42.057102, -87.676943) //ford
//        let startLine = CLLocationCoordinate2DMake(42.058175, -87.683502) //noyes el
//        let startLine = CLLocationCoordinate2DMake(42.051169, -87.677232) //arch
        let startLine = CLLocationCoordinate2DMake(41.783188, -87.584535) //race -- reset for demo
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
        
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUser_data), userInfo: nil, repeats: true) //TODO: avoid race condition with timers -- set UI timer slower or data faster
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUser_UI), userInfo: nil, repeats: true)
    }
    
    func monitorUser_data() {
        //monitor runner
        print("monitoring runner -- data loop")
        
        if (runnerMonitor.startRegionState == "inside" || runnerMonitor.startRegionState == "exited" || runnerMonitor.startRegionState == "monitoring") {
            
            //start runner monitor
            runnerMonitor.monitorUserLocation()
            runnerMonitor.updateUserPath(interval)
            runnerMonitor.updateUserLocation()
        
            //check for nearby spectators
            updateNearbySpectators()
        }
        
        if runnerMonitor.startRegionState == "exited" {
            resetTracking()
            runnerMonitor.startRegionState = "monitoring"
        }
    }
    
    func monitorUser_UI() {
        //monitor runner
        print("monitoring runner -- UI loop")
        
        if (runnerMonitor.startRegionState == "inside" || runnerMonitor.startRegionState == "exited" || runnerMonitor.startRegionState == "monitoring") {
            
            if UIApplication.shared.applicationState == .background {
                print("app status: \(UIApplication.shared.applicationState)")
                runnerMonitor.enableBackgroundLoc()
            }
            
            //update runner UI
            distance.text = "Distance: " + String(format: " %.02f", runnerMonitor.metersToMiles(runnerMonitor.distance)) + "mi"
            let timeString = runnerMonitor.stringFromSeconds(runnerMonitor.duration)
            time.text = "Time: " + timeString + " s"
            pace.text = "Pace: " + (runnerMonitor.pace as String)
            
            if let currLoc = runnerMonitor.locationMgr.location {
                if CLLocationCoordinate2DIsValid(currLoc.coordinate) {
                    if (runnerMonitor.locationMgr.location!.coordinate.latitude != 0.0 && runnerMonitor.locationMgr.location!.coordinate.longitude != 0.0) {  //NOTE: nil here
                        
                        runnerPath.append((runnerMonitor.locationMgr.location?.coordinate)!)
                        //                    drawPath()
                    }
                }
            }
        }
    }
    
    func updateNearbySpectators() {
        //every x seconds, update array of nearby spectators and change location frequency accordingly
        
        nearbySpectators = NearbySpectators()
        nearbySpectators.checkProximityZone(){ (spectatorLocations) -> Void in
            
            if ((spectatorLocations?.isEmpty) == true) {
                self.areSpectatorsNearby = false
                if self.userMonitorTimer_data.timeInterval < 30 {
                    self.userMonitorTimer_data.invalidate()
                    self.userMonitorTimer_UI.invalidate()
                    self.interval = 30
                    self.userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(RunViewController.monitorUser_data), userInfo: nil, repeats: true)
                    self.userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(RunViewController.monitorUser_UI), userInfo: nil, repeats: true)
                    self.nearbySpectators.locationMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
                }
            }
            else {
                self.areSpectatorsNearby = true
                self.userMonitorTimer_data.invalidate()
                self.userMonitorTimer_UI.invalidate()
                self.interval = 3 //TODO: check if this is too frequent based on checkProximityZone for spectators
                self.userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(RunViewController.monitorUser_data), userInfo: nil, repeats: true)
                self.userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(RunViewController.monitorUser_UI), userInfo: nil, repeats: true)
                self.nearbySpectators.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
            }
        }
    }
    
    func locationTrackingAlert() {
        let alertTitle = "Runner Tracking"
        let alertController = UIAlertController(title: alertTitle, message: "Before you start the race, check to see if tracking has started. Tracking should automatically start when you arrive on race day.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func resetTracking() {
        print("Reset tracking")
        runnerMonitor = RunnerMonitor()
        runnerMonitor.startRegionState = "exited" //NOTE: not great to modify model from VC
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUser_data), userInfo: nil, repeats: true)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUser_UI), userInfo: nil, repeats: true)
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

    @IBAction func start(_ sender: UIButton) {
        //allow runner to manually start if automatic tracking does not work
        
        runnerMonitor = RunnerMonitor()
        runnerMonitor.startRegionState = "monitoring" //NOTE: not great to modify model from VC
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUser_data), userInfo: nil, repeats: true)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(RunViewController.monitorUser_UI), userInfo: nil, repeats: true)
        
        congrats.isHidden = true
        start.isHidden = true
        distance.isHidden = false
        time.isHidden = false
        pace.isHidden = false
        pause.isHidden = false
        stop.isHidden = false
        
    }
    
    @IBAction func stop(_ sender: UIButton) {
        //suspend runner monitor when you hit stop
        
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
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
        
        userMonitorTimer_data.fire()
        userMonitorTimer_UI.fire()
        pause.isHidden = false
        resume.isHidden = true
    }
}
