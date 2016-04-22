//
//  TrackViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/1/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Parse

class TrackViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var locationMgr: CLLocationManager = CLLocationManager()
    var runnerTrackerTimer: NSTimer = NSTimer()
    var userMonitorTimer: NSTimer = NSTimer()
    var runner: PFUser = PFUser()
    var runnerPic: UIImage = UIImage()
    var runnerName: String = ""
    var runnerBib: String = ""
    var myLocation = CLLocation()
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var contextPrimer = ContextPrimer()
    var cheererMonitor: CheererMonitor = CheererMonitor()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize map
        //update the runner profile info
        //every second, update the distance label and map with the runner's location

        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        getRunnerProfile()
        self.distanceLabel.text = "Loading location..."
        self.locationMgr = CLLocationManager()
        self.myLocation = self.locationMgr.location!
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        self.runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(TrackViewController.trackRunner), userInfo: nil, repeats: true)
        self.userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(TrackViewController.monitorUser), userInfo: nil, repeats: true)
        self.contextPrimer = ContextPrimer()
        self.cheererMonitor = CheererMonitor()
        
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
    
    func trackRunner() {
        //get latest loc and update map and distance label
        
        print("Tracking runner")
        
        if self.locationMgr.location != nil {
            self.myLocation = self.locationMgr.location!
        }
        else {
            print(self.locationMgr.location)
            print(self.myLocation)
        }
        
        let trackedRunnerID: String = self.runner.objectId //NOTE: runner is empty, check getRunnerProfile
        
        self.contextPrimer.getRunnerLocation(trackedRunnerID) { (runnerLoc) -> Void in

            self.runnerLastLoc = runnerLoc
        }
        
        if (self.runnerLastLoc.latitude == 0.0 && self.runnerLastLoc.longitude == 0.0) {
            print("skipping coordinate")
        }
        else {
            self.runnerPath.append(self.runnerLastLoc)
            let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
            let distance = (self.myLocation.distanceFromLocation(runnerCLLoc))
            self.distanceLabel.text = String(format: " %.02f", distance) + "m away"
            self.distanceLabel.hidden = false
            
            if (distance >= 100 && distance <= 150) {
                self.sendLocalNotification(self.runnerName)
            }
            
            else if distance<100 {
                self.runnerTrackerTimer.invalidate()
                self.userMonitorTimer.invalidate()
                self.performSegueWithIdentifier("runnerNear", sender: nil) //NOTE: Race testing errored here
            }
        }
        
        drawPath()
        updateRunnerPin()
    }
    
    func getRunnerProfile() {
        
        self.contextPrimer.getRunner(){ (runnerObjectID) -> Void in
            //update runner name, bib #, picture
            print("runnerObjID: ", runnerObjectID)
            
            do {
                self.runner = try PFQuery.getUserObjectWithId(runnerObjectID, error: ())
            }
                
            catch _ {
                let loggedError = PFObject(className: "ErrorLog")
                loggedError["event"] = "TrackVC: getRunnerProfile"
                loggedError["error"] = "runnerObjectID query: \(runnerObjectID)"
                loggedError.saveInBackground()

                return print("ERROR: runnerObjectID \(runnerObjectID) not found")
            }
            
            let name = (self.runner.valueForKey("name"))!
            let bib = (self.runner.valueForKey("bibNumber"))!
            let userImageFile = self.runner["profilePic"] as? PFFile
            userImageFile!.getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        let image = UIImage(data:imageData)
                        self.runnerPic = image!
                    }
                }
            }
            self.runnerName = (name as? String)!
            self.runnerBib = (bib as? String)!
        }
    }
    
    
    func sendLocalNotification(name: String) {
        let localNotification = UILocalNotification()
        localNotification.alertBody = "Time to cheer for " + name + "!"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
        
        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
    }
    
    func drawPath() {
        
        if(self.runnerPath.count > 1) {
            let polyline = MKPolyline(coordinates: &self.runnerPath[0] , count: self.runnerPath.count)
            self.mapView.addOverlay(polyline)
        }
        
    }
    
    func updateRunnerPin() {
        
        let coordinate = self.runnerLastLoc
        let title = self.runnerName
        let type = RunnerType(rawValue: 0) //type would be 1 if it's my runner
        let subtitle = ("Bib #:" + self.runnerBib)
        let image = self.runnerPic
        let annotation = TrackRunnerAnnotation(coordinate: coordinate, title: title, subtitle: subtitle, type: type!, image: image)

        let annotationsToRemove = self.mapView.annotations.filter { $0 !== self.mapView.userLocation }
        self.mapView.removeAnnotations(annotationsToRemove)
        self.mapView.addAnnotation(annotation)
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        else {
            let annotationView = TrackRunnerAnnotationView(annotation: annotation, reuseIdentifier: "Runner")
            annotationView.canShowCallout = true
            
            
            let runnerPicView = UIImageView.init(image: self.runnerPic)
            let frameSize = CGSizeMake(60, 60)
            
            var picFrame = runnerPicView.frame
            picFrame.size = frameSize
            runnerPicView.frame = picFrame
            annotationView.leftCalloutAccessoryView = runnerPicView
            return annotationView
        }
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        if (mapView.annotations.first is MKUserLocation) {
            mapView.selectAnnotation(mapView.annotations.last!, animated: true)
        }
        
        else {
            mapView.selectAnnotation(mapView.annotations.first!, animated: true)
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
}