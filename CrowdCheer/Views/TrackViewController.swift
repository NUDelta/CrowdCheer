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
    
    @IBOutlet weak var cheerForBanner: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var cheer: UILabel!
    @IBOutlet weak var outfit: UILabel!
    @IBOutlet weak var ETA: UILabel!
    @IBOutlet weak var redLabel: UILabel!
    
    var runnerTrackerTimer: Timer = Timer()
    var userMonitorTimer: Timer = Timer()
    var nearbyRunnersTimer: Timer = Timer()
    var interval: Int = Int()
    var trackedRunner: PFUser = PFUser()
    var runnerPic: UIImage = UIImage()
    var runnerName: String = ""
    var runnerBib: String = ""
    var runnerCheer: String = ""
    var runnerOutfit: String = ""
    var myLocation = CLLocation()
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var runnerLocations = [PFUser: PFGeoPoint]()
    var nearbyTargetRunners = [String: Bool]()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var contextPrimer: ContextPrimer = ContextPrimer()
    var verifiedReceival: VerifiedReceival = VerifiedReceival()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize map
        //update the runner profile info
        //every 5 seconds, update the distance label and map with the runner's location

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true);
        let headingBtn = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.rightBarButtonItem = headingBtn
        
        getRunnerProfile()
        ETA.text = "Loading location..."
        myLocation = contextPrimer.locationMgr.location!
        interval = 5
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        runnerTrackerTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.trackRunner), userInfo: nil, repeats: true)
        userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        spectatorMonitor = SpectatorMonitor()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
        userMonitorTimer.invalidate()
        runnerTrackerTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        
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
        
        contextPrimer.getRunnerLocation(trackedRunner) { (runnerLoc) -> Void in

            self.runnerLastLoc = runnerLoc
        }
        
        let actualTime = contextPrimer.actualTime
        let setTime = contextPrimer.setTime
        let getTime = contextPrimer.getTime
        let showTime = Date()
        let latencyData = contextPrimer.handleLatency(trackedRunner, actualTime: actualTime, setTime: setTime, getTime: getTime, showTime: showTime)
        
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
            ETA.text = String(format: " %d", Int(distanceCalc)) + "m away"
            ETA.isHidden = false
            
            if (distanceCalc >= 100 && distanceCalc <= 150) {
                sendLocalNotification(runnerName)
                ETA.textColor = redLabel.textColor
            }
            
            else if distanceCalc<100 {
                runnerTrackerTimer.invalidate()
                userMonitorTimer.invalidate()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CheerViewController") as UIViewController
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        updateRunnerInfo()

    }
    
    func updateNearbyRunners() {
        //find nearby favorite runners and notify if close by
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            if ((runnerLocations?.isEmpty) != true) {
                self.runnerLocations = runnerLocations!
                
                self.optimizedRunners.considerAffinity(self.runnerLocations) { (affinities) -> Void in
                    print("affinities \(affinities)")
                    
                    for (runner, runnerLoc) in runnerLocations! {
                        
                        //calculate the distance between spectator and a runner
                        
                        let runnerCLLoc = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                        let dist = runnerCLLoc.distance(from: self.optimizedRunners.locationMgr.location!)
                        print(runner.username!, dist)
                        
                        //for each runner, find closeby target runners
                        for affinity in affinities {
                            
                            if runner == affinity.0 {
                                //Goal: Show target runners throughout the race
                                if dist <= 500 { //if runner is less than 500m away (demo: 250)
                                    if affinity.1 == 10 && runner.objectId != self.trackedRunner.objectId { //if target runner and if runner is not the same
                                        //notify
                                        let name = (runner.value(forKey: "name"))!
                                        self.sendLocalNotification_target(name as! String)
                                    }
                                }
                            }
                        }
                    }
                    
                    self.nearbyTargetRunners = self.optimizedRunners.targetRunners
                }
            }
        }
    }
    
    func updateRunnerInfo() {
//        drawPath()
        updateRunnerPin()
    }
    
    func getRunnerProfile() {
        
        trackedRunner = contextPrimer.getRunner()
        let name = (trackedRunner.value(forKey: "name"))!
        let bib = (trackedRunner.value(forKey: "bibNumber"))!
        let cheer = (trackedRunner.value(forKey: "cheer"))!
        let outfit = (trackedRunner.value(forKey: "outfit"))!
        let userImageFile = trackedRunner["profilePic"] as? PFFile
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
        runnerCheer = (cheer as? String)!
        runnerOutfit = (outfit as? String)!
        
        self.cheer.text = "\(runnerName) wants you to cheer: \n\(runnerCheer)"
        self.outfit.text = "\(runnerName) is wearing: \n\(runnerOutfit)"
        self.cheerForBanner.text = "Cheer for \(runnerName)"
        
        
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
    
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            // render the path
//            assert(overlay.isKind(of: MKPolyline.self))
//            let polyLine = overlay
//            let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
//            polyLineRenderer.strokeColor = UIColor.blue
//            polyLineRenderer.lineWidth = 3.0
//            
//            return polyLineRenderer
//
//    }
    
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
    
    func sendLocalNotification(_ name: String) {
        let localNotification = UILocalNotification()
        let notificationID = arc4random_uniform(10000000)
        
        var spectatorInfo = [String: AnyObject]()
        spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
        spectatorInfo["source"] = "track_targetRunnerNearbyNotification" as AnyObject
        spectatorInfo["notificationID"] = notificationID as AnyObject
        spectatorInfo["receivedNotification"] = true as AnyObject
        spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
        
        localNotification.alertBody = "Time to cheer for " + name + "!"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        
        spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
        localNotification.userInfo = spectatorInfo
        
        let newNotification = PFObject(className: "SpectatorNotifications")
        newNotification["spectator"] = localNotification.userInfo!["spectator"]
        newNotification["source"] = localNotification.userInfo!["source"]
        newNotification["notificationID"] = notificationID
        newNotification["sentNotification"] = true
        newNotification["sentNotificationTimestamp"] = Date() as AnyObject
        newNotification["unreadNotificationCount"] = localNotification.userInfo!["unreadNotificationCount"]
        newNotification.saveInBackground()
        
        
        UIApplication.shared.presentLocalNotificationNow(localNotification)
    }
    
    func sendLocalNotification_target(_ name: String) {
        
        if UIApplication.shared.applicationState == .background {
            
            let localNotification = UILocalNotification()
            let notificationID = arc4random_uniform(10000000)
            
            var spectatorInfo = [String: AnyObject]()
            spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
            spectatorInfo["source"] = "track_targetRunnerNearbyNotification_general" as AnyObject
            spectatorInfo["notificationID"] = notificationID as AnyObject
            spectatorInfo["receivedNotification"] = true as AnyObject
            spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
            
            localNotification.alertBody =  name + " is nearby, get ready to support them!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
            
            spectatorInfo["unreadNotificationCount"] = localNotification.applicationIconBadgeNumber as AnyObject
            localNotification.userInfo = spectatorInfo
            
            let newNotification = PFObject(className: "SpectatorNotifications")
            newNotification["spectator"] = localNotification.userInfo!["spectator"]
            newNotification["source"] = localNotification.userInfo!["source"]
            newNotification["notificationID"] = notificationID
            newNotification["sentNotification"] = true
            newNotification["sentNotificationTimestamp"] = Date() as AnyObject
            newNotification["unreadNotificationCount"] = localNotification.userInfo!["unreadNotificationCount"]
            newNotification.saveInBackground()
            
            UIApplication.shared.presentLocalNotificationNow(localNotification)
        }
            
        else if UIApplication.shared.applicationState == .active {
            
            let alertTitle = name + " is nearby!"
            let alertController = UIAlertController(title: alertTitle, message: "Get ready to support them!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Cheer", style: UIAlertActionStyle.default, handler: cheerForTarget))
            alertController.addAction(UIAlertAction(title: "Not now", style: UIAlertActionStyle.default, handler: dismissCheerTarget))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func cheerForTarget(_ alert: UIAlertAction!) {
        
        nearbyRunnersTimer.invalidate()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DashboardViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func dismissCheerTarget(_ alert: UIAlertAction!) {
        
        nearbyRunnersTimer.invalidate()
    }

}
