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
    
    var runnerTrackerTimer: Timer = Timer()
    var userMonitorTimer: Timer = Timer()
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
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        getRunnerProfile()
        distanceLabel.text = "Loading location..."
        myLocation = contextPrimer.locationMgr.location!
        interval = 5
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        runnerTrackerTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.trackRunner), userInfo: nil, repeats: true)
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.monitorUser), userInfo: nil, repeats: true)
        contextPrimer = ContextPrimer()
        spectatorMonitor = SpectatorMonitor()
        
    }
    
        override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
        userMonitorTimer.invalidate()
        runnerTrackerTimer.invalidate()
        
    }
    
    func monitorUser() {
        
        //start cheerer tracker
        spectatorMonitor.monitorUserLocation()
        spectatorMonitor.updateUserLocation()
        spectatorMonitor.updateUserPath(interval)
        
        if UIApplication.shared.applicationState == .background {
            print("app status: \(UIApplication.shared.applicationState))")
            
            spectatorMonitor.enableBackgroundLoc()
        }
    }
    
    func trackRunner() {
        //get latest loc and update map and distance label
        
        print("Tracking runner")
        
        if contextPrimer.locationMgr.location != nil {
            myLocation = contextPrimer.locationMgr.location!
        }
        else {
            //do nothing
        }
        
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in

            self.runnerLastLoc = runnerLoc
        }
        
        let actualTime = contextPrimer.actualTime
        let setTime = contextPrimer.setTime
        let getTime = contextPrimer.getTime
        let showTime = Date()
        let latencyData = contextPrimer.handleLatency(runner, actualTime: actualTime, setTime: setTime, getTime: getTime, showTime: showTime)
        
        if (runnerLastLoc.latitude == 0.0 && runnerLastLoc.longitude == 0.0) {
            print("skipping coordinate")
        }
        else {
            runnerPath.append(runnerLastLoc)
            let runnerCLLoc = CLLocation(latitude: runnerLastLoc.latitude, longitude: runnerLastLoc.longitude)
            let distanceLast = (contextPrimer.locationMgr.location!.distance(from: runnerCLLoc))
            var distanceCalc = distanceLast - contextPrimer.calculateDistTraveled(latencyData.delay, speed: contextPrimer.speed)
            if distanceCalc < 0 {
                distanceCalc = 0.01
            }
            distanceLabel.text = String(format: " %.02f", distanceCalc) + "m away"
            distanceLabel.isHidden = false
            
            if (distanceCalc >= 100 && distanceCalc <= 150) {
                sendLocalNotification(runnerName)
            }
            
            else if distanceCalc<100 {
                runnerTrackerTimer.invalidate()
                userMonitorTimer.invalidate()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CheerViewController") as UIViewController
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        
//        drawPath()
        updateRunnerPin()
    }
    
    func getRunnerProfile() {
        
        runner = contextPrimer.getRunner()
        let name = (runner.value(forKey: "name"))!
        let bib = (runner.value(forKey: "bibNumber"))!
        let userImageFile = runner["profilePic"] as? PFFile
        userImageFile!.getDataInBackground {
            (imageData: Data?, error: Error?) -> Void in
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
    
    
    func sendLocalNotification(_ name: String) {
        let localNotification = UILocalNotification()
        localNotification.alertBody = "Time to cheer for " + name + "!"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        
        UIApplication.shared.presentLocalNotificationNow(localNotification)
    }
    
    func drawPath() {
        
        if(runnerPath.count > 1) {
            print("runnerPath is \(runnerPath)")
            let polyline = MKPolyline(coordinates: &runnerPath[0] , count: runnerPath.count)
            mapView.add(polyline)
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // render the path
            assert(overlay.isKind(of: MKPolyline.self))
            let polyLine = overlay
            let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
            polyLineRenderer.strokeColor = UIColor.blue
            polyLineRenderer.lineWidth = 3.0
            
            return polyLineRenderer

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        else {
            let annotationView = TrackRunnerAnnotationView(annotation: annotation, reuseIdentifier: "Runner")
            annotationView.canShowCallout = true
            
            
            let runnerPicView = UIImageView.init(image: runnerPic)
            let frameSize = CGSize(width: 60, height: 60)
            
            var picFrame = runnerPicView.frame
            picFrame.size = frameSize
            runnerPicView.frame = picFrame
            annotationView.leftCalloutAccessoryView = runnerPicView
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        
        if (mapView.annotations.first is MKUserLocation) {
            mapView.selectAnnotation(mapView.annotations.last!, animated: true)
        }
        
        else {
            mapView.selectAnnotation(mapView.annotations.first!, animated: true)
        }
        
        
    }
}
