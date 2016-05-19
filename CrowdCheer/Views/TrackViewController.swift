//
//  TrackViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/1/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import MapKit
import Parse

class TrackViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var runnerTrackerTimer: NSTimer = NSTimer()
    var userMonitorTimer: NSTimer = NSTimer()
    var interval: Int = Int()
    var runner: PFUser = PFUser()
    var runnerPic: UIImage = UIImage()
    var runnerName: String = ""
    var runnerBib: String = ""
    var myLocation = CLLocation()
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var contextPrimer = ContextPrimer()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize map
        //update the runner profile info
        //every second, update the distance label and map with the runner's location

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        getRunnerProfile()
        distanceLabel.text = "Loading location..."
        myLocation = contextPrimer.location
        interval = 5
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(TrackViewController.trackRunner), userInfo: nil, repeats: true)
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(TrackViewController.monitorUser), userInfo: nil, repeats: true)
        contextPrimer = ContextPrimer()
        spectatorMonitor = SpectatorMonitor()
        
    }
    
    func monitorUser() {
        
        //start cheerer tracker
        spectatorMonitor.monitorUserLocation()
        spectatorMonitor.updateUserLocation()
        spectatorMonitor.updateUserPath(interval)
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState))")
            
            spectatorMonitor.enableBackgroundLoc()
        }
    }
    
    func trackRunner() {
        //get latest loc and update map and distance label
        
        print("Tracking runner")
        
        if contextPrimer.location != nil {
            myLocation = contextPrimer.location
        }
        else {
            print(contextPrimer.locationMgr.location)
            print(myLocation)
        }
        
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in

            self.runnerLastLoc = runnerLoc
        }
        
        if (runnerLastLoc.latitude == 0.0 && runnerLastLoc.longitude == 0.0) {
            print("skipping coordinate")
        }
        else {
            runnerPath.append(runnerLastLoc)
            let runnerCLLoc = CLLocation(latitude: runnerLastLoc.latitude, longitude: runnerLastLoc.longitude)
            let distance = (myLocation.distanceFromLocation(runnerCLLoc))
            distanceLabel.text = String(format: " %.02f", distance) + "m away"
            distanceLabel.hidden = false
            
            if (distance >= 100 && distance <= 150) {
                sendLocalNotification(runnerName)
            }
            
            else if distance<100 {
                runnerTrackerTimer.invalidate()
                userMonitorTimer.invalidate()
                performSegueWithIdentifier("runnerNear", sender: nil) //NOTE: Race testing errored here
            }
        }
        
        drawPath()
        updateRunnerPin()
    }
    
    func getRunnerProfile() {
        
        runner = contextPrimer.getRunner()
        let name = (runner.valueForKey("name"))!
        let bib = (runner.valueForKey("bibNumber"))!
        let userImageFile = runner["profilePic"] as? PFFile
        userImageFile!.getDataInBackgroundWithBlock {
            (imageData: NSData?, error: NSError?) -> Void in
            if error == nil {
                if let imageData = imageData {
                    let image = UIImage(data:imageData)
                    self.runnerPic = image!
                }
            }
        }
        runnerName = (name as? String)!
        runnerBib = (bib as? String)!
    }
    
    
    func sendLocalNotification(name: String) {
        let localNotification = UILocalNotification()
        localNotification.alertBody = "Time to cheer for " + name + "!"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
        
        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
    }
    
    func drawPath() {
        
        if(runnerPath.count > 1) {
            let polyline = MKPolyline(coordinates: &runnerPath[0] , count: runnerPath.count)
            mapView.addOverlay(polyline)
        }
        
    }
    
    func updateRunnerPin() {
        
        let coordinate = runnerLastLoc
        let title = runnerName
        let type = RunnerType(rawValue: 0) //type would be 1 if it's my runner
        let subtitle = ("Bib #:" + runnerBib)
        let image = runnerPic
        let annotation = TrackRunnerAnnotation(coordinate: coordinate, title: title, subtitle: subtitle, type: type!, image: image)

        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations(annotationsToRemove)
        mapView.addAnnotation(annotation)
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
            
            
            let runnerPicView = UIImageView.init(image: runnerPic)
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
}