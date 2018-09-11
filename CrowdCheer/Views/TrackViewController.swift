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
    @IBOutlet weak var supportRunner: UIButton!
    @IBOutlet weak var waitToCheer: UILabel!
    
    
    var runnerTrackerTimer: Timer = Timer()
    var userMonitorTimer_data: Timer = Timer()
    var userMonitorTimer_UI: Timer = Timer()
    var nearbyRunnersTimer: Timer = Timer()
    var interval: Int = Int()
    var trackedRunner: PFUser = PFUser()
    var didChooseToCheer: Bool = Bool()
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
    var verifiedDelivery: VerifiedDelivery = VerifiedDelivery()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "TrackVC"

    
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
        
        print("viewWillDisappear")
        userMonitorTimer_data.invalidate()
        userMonitorTimer_UI.invalidate()
        runnerTrackerTimer.invalidate()
        nearbyRunnersTimer.invalidate()

        
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
        supportRunner.isHidden = false
        waitToCheer.isHidden = true
        myLocation = contextPrimer.locationMgr.location!
        interval = 5
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
//        DispatchQueue.global(qos: .background).async {
//            self.runnerTrackerTimer = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(TrackViewController.trackRunner), userInfo: nil, repeats: true)
//            let runLoop = RunLoop.current
//            runLoop.add(self.runnerTrackerTimer, forMode: .defaultRunLoopMode)
//            runLoop.run()
//        }
        
//        DispatchQueue.global(qos: .background).async {
//            self.userMonitorTimer = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(TrackViewController.monitorUser), userInfo: nil, repeats: true)
//            let runLoop = RunLoop.current
//            runLoop.add(self.userMonitorTimer, forMode: .defaultRunLoopMode)
//            runLoop.run()
//        }
        
//        DispatchQueue.global(qos: .background).async {
//            self.nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(self.interval), target: self, selector: #selector(TrackViewController.updateNearbyRunners), userInfo: nil, repeats: true)
//            let runLoop = RunLoop.current
//            runLoop.add(self.nearbyRunnersTimer, forMode: .defaultRunLoopMode)
//            runLoop.run()
//        }
        
       //tracking runner -- data + UI timers
//        runnerTrackerTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.trackRunner), userInfo: nil, repeats: true)
        
        //monitoring spectators -- data + UI timers
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.monitorUser_data), userInfo: nil, repeats: true)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.monitorUser_data), userInfo: nil, repeats: true)
        
        //finding nearby R* runners -- data + UI timers
//        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(TrackViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        spectatorMonitor = SpectatorMonitor()
        verifiedDelivery = VerifiedDelivery()
        
    }
    
    func monitorUser_data() {
        
        DispatchQueue.global(qos: .background).async {
        
            //start cheerer tracker
            self.spectatorMonitor.monitorUserLocation()
            self.spectatorMonitor.updateUserLocation()
            self.spectatorMonitor.updateUserPath(self.interval)
        }
    }
    
    func monitorUser_UI() {
        
        DispatchQueue.main.async {

            if UIApplication.shared.applicationState == .background {
                print("app status: \(UIApplication.shared.applicationState))")
                
                self.spectatorMonitor.enableBackgroundLoc()
            }
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

            print("#####################")
            print("getrunnerloc callback running")
            self.runnerLastLoc = runnerLoc
        }
        
        //this logic should go in callback
        print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
        print(" runnerlastloc: \(self.runnerLastLoc) \n ")
        
        let actualTime = contextPrimer.actualTime
        let setTime = contextPrimer.setTime
        let getTime = contextPrimer.getTime
        let showTime = Date()
        let latencyData = contextPrimer.handleLatency(trackedRunner, actualTime: actualTime, setTime: setTime, getTime: getTime, showTime: showTime)
        
        if(CLLocationCoordinate2DIsValid(self.runnerLastLoc)) {
            if (self.runnerLastLoc.latitude != 0.0 && self.runnerLastLoc.longitude != 0.0) {
                
                //append to runner path
                runnerPath.append(self.runnerLastLoc)
                
                //convert to CLLocation
                let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
                
                //store last known distance between spectator & runner
                let distanceLast = (contextPrimer.locationMgr.location!.distance(from: runnerCLLoc))
                
                //calculate the simulated distance traveled during the delay (based on speed + delay)
                let distanceTraveledinLatency = contextPrimer.calculateDistTraveled(latencyData.delay, speed: contextPrimer.speed)
                
                //subtract the simulated distance traveled during the delay (based on speed + delay) from the last known distance from spectator to give us an updated distance from spectator
                var distanceCalc = distanceLast -  distanceTraveledinLatency
                
                print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
                print(" distfromMeCalc: \(distanceCalc) \n distLast: \(distanceLast) \n distTraveled: \(distanceTraveledinLatency)")
                
                //use calculated distance between spectator and runner now
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
                    userMonitorTimer_data.invalidate()
                    userMonitorTimer_UI.invalidate()
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "CheerViewController") as UIViewController
                    navigationController?.pushViewController(vc, animated: true)
                }
                
                updateRunnerInfo()
            }
        }
        
        //updateRunnerInfo()
    }
    
    func updateNearbyRunners() {
        //find nearby favorite runners and notify if close by
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            if ((runnerLocations?.isEmpty) != true) {
                self.runnerLocations = runnerLocations!
                self.verifiedDelivery = VerifiedDelivery()
                
                self.optimizedRunners.considerAffinity(self.runnerLocations) { (affinities) -> Void in
                    print("affinities \(affinities)")
                    
                    for (runner, runnerLoc) in runnerLocations! {
                        
                        //calculate the distance between spectator and a runner
                        
                        let runnerCLLoc = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                        let dist = runnerCLLoc.distance(from: self.optimizedRunners.locationMgr.location!)
                        print(runner.username!, dist)
                        
                        //for each runner, find closeby target runners
                        for affinity in affinities {
                            var didSpectatorCheerRecently = false
                            if runner == affinity.0 {
                                //Goal: Show target runners throughout the race
                                if dist <= 250 { //if runner is less than 500m away (400 for 5/10k) (demo: 250)
                                    if affinity.1 == 10 && runner.objectId != self.trackedRunner.objectId { //if target runner and if runner is not the same
                                        self.verifiedDelivery.didSpectatorCheerRecently(runner) { (didCheerRecently) -> Void in
                                            
                                            didSpectatorCheerRecently = didCheerRecently
                                            if !didSpectatorCheerRecently { //if I did not just cheer for target runner (last 10 min)
                                                //notify
                                                let name = (runner.value(forKey: "name"))!
                                                self.sendLocalNotification_target(name as! String)
                                            }
                                            
                                        }
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
        if (contextPrimer.getRunner().username != nil) {
            trackedRunner = contextPrimer.getRunner()
        }
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
            
            localNotification.alertBody =  name + " is nearby, view their status now!"
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
            let alertController = UIAlertController(title: alertTitle, message: "View their status so you don't miss them!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "View " + name, style: UIAlertActionStyle.default, handler: cheerForTarget))
            alertController.addAction(UIAlertAction(title: "Keep cheering for " + runnerName, style: UIAlertActionStyle.default, handler: cheerForGeneral))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func cheerForTarget(_ alert: UIAlertAction!) {
        
        let newNotification = PFObject(className: "SpectatorNotifications")
        let notificationID = arc4random_uniform(10000000)
        newNotification["spectator"] = PFUser.current()?.objectId
        newNotification["source"] = "track_cheerForTarget"
        newNotification["notificationID"] = notificationID
        newNotification["sentNotification"] = true
        newNotification["receivedNotification"] = true
        newNotification["receivedNotificationTimestamp"] = Date() as AnyObject
        newNotification.saveInBackground()
        
        nearbyRunnersTimer.invalidate()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DashboardViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func cheerForGeneral(_ alert: UIAlertAction!) {
        
        let newNotification = PFObject(className: "SpectatorNotifications")
        let notificationID = arc4random_uniform(10000000)
        newNotification["spectator"] = PFUser.current()?.objectId
        newNotification["source"] = "track_cheerForGeneral"
        newNotification["notificationID"] = notificationID
        newNotification["sentNotification"] = true
        newNotification["receivedNotification"] = true
        newNotification["receivedNotificationTimestamp"] = Date() as AnyObject
        newNotification.saveInBackground()
        
        nearbyRunnersTimer.invalidate()
    }
    
    @IBAction func supportRunner(_ sender: UIButton) {
        //update "cheer" object -- the runner:spectator pairing -- indicating that spectator wants to support runner
        
        didChooseToCheer = true
        contextPrimer.spectatorChoseToSupport(trackedRunner, didChooseToCheer: didChooseToCheer)
        supportRunner.isHidden = true
        waitToCheer.isHidden = false
    }

}
