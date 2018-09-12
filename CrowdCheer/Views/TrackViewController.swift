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
    
    
    var runnerTrackerTimer_data: Timer = Timer()
    var runnerTrackerTimer_UI: Timer = Timer()
    var userMonitorTimer_data: Timer = Timer()
    var userMonitorTimer_UI: Timer = Timer()
    var nearbyRunnersTimer: Timer = Timer()
    var intervalData: Int = Int()
    var intervalUI: Int = Int()
    var trackedRunner: PFUser = PFUser()
    var calculateRunnerLocation: Bool = Bool()
    var latencyData: (delay: TimeInterval, calculatedRunnerLoc: CLLocationCoordinate2D) = (0.0, CLLocationCoordinate2D())
    var distanceCalc: Double = Double()
    var didChooseToCheer: Bool = Bool()
    var runnerPic: UIImage = UIImage()
    var runnerName: String = ""
    var runnerBib: String = ""
    var runnerCheer: String = ""
    var runnerOutfit: String = ""
    var myLocation = CLLocation()
    var runnerPrevLoc = CLLocationCoordinate2D()
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
        runnerTrackerTimer_data.invalidate()
        runnerTrackerTimer_UI.invalidate()
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
        distanceCalc = -1
        calculateRunnerLocation = false
        ETA.text = "Loading location..."
        supportRunner.isHidden = false
        waitToCheer.isHidden = true
        myLocation = contextPrimer.locationMgr.location!
        intervalData = 4
        intervalUI = 6
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
       //tracking runner -- data + UI timers
        runnerTrackerTimer_data = Timer.scheduledTimer(timeInterval: Double(intervalData), target: self, selector: #selector(TrackViewController.trackRunner_data), userInfo: nil, repeats: true)
        runnerTrackerTimer_UI = Timer.scheduledTimer(timeInterval: Double(intervalUI), target: self, selector: #selector(TrackViewController.trackRunner_UI), userInfo: nil, repeats: true)
        
        //monitoring spectator -- data + UI timers
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(intervalData), target: self, selector: #selector(TrackViewController.monitorUser_data), userInfo: nil, repeats: true)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(intervalUI), target: self, selector: #selector(TrackViewController.monitorUser_data), userInfo: nil, repeats: true)
        
        //finding nearby R* runners -- data + UI timer
        nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: Double(intervalUI), target: self, selector: #selector(TrackViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        spectatorMonitor = SpectatorMonitor()
        verifiedDelivery = VerifiedDelivery()
        
    }
    
    func monitorUser_data() {
    
        DispatchQueue.global(qos: .utility).async {
        
            //start spectator tracker
            self.spectatorMonitor.monitorUserLocation()
            self.spectatorMonitor.updateUserLocation()
            self.spectatorMonitor.updateUserPath(self.intervalData)
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
    
    func trackRunner_data() {
        
        DispatchQueue.global(qos: .utility).async {
            
            print("Tracking runner - data - trackVC")
            
            //1. get most recent runner locations
            if self.contextPrimer.locationMgr.location != nil {
                self.myLocation = self.contextPrimer.locationMgr.location!
            }
            else {
                //do nothing
            }
            
            self.contextPrimer.getRunnerLocation(self.trackedRunner) { (runnerLoc) -> Void in

                DispatchQueue.global(qos: .utility).async {
                    print("getrunnerloc callback running - trackVC")
                    self.runnerLastLoc = runnerLoc
                }
            }
            
            print(" runnerlastloc - trackVC: \(self.runnerLastLoc) \n ")
            
            //2. calculate latency data
            let actualTime = self.contextPrimer.actualTime
            let setTime = self.contextPrimer.setTime
            let getTime = self.contextPrimer.getTime
            let showTime = Date()
            self.latencyData = self.contextPrimer.handleLatency(self.trackedRunner, actualTime: actualTime, setTime: setTime, getTime: getTime, showTime: showTime)
            
            
            //3. calculate distance between spectator & runner using current latency
            if(CLLocationCoordinate2DIsValid(self.runnerLastLoc)) {
                if (self.runnerLastLoc.latitude != 0.0 && self.runnerLastLoc.longitude != 0.0) {
                    
                    //append to runner path
                    self.runnerPath.append(self.runnerLastLoc)
                    
                    //convert to CLLocation
                    let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
                    
                    //store last known distance between spectator & runner
                    let distanceLast = (self.myLocation.distance(from: runnerCLLoc))
                    
                    //calculate the simulated distance traveled during the delay (based on speed + delay)
                    let distanceTraveledinLatency = self.contextPrimer.calculateDistTraveled(self.latencyData.delay, speed: self.contextPrimer.speed)
                    
                    //subtract the simulated distance traveled during the delay (based on speed + delay) from the last known distance from spectator to give us an updated distance from spectator
                    self.distanceCalc = distanceLast -  distanceTraveledinLatency
                    
                    print(" trackVC: \n distfromMeCalc: \(self.distanceCalc) \n distLast: \(distanceLast) \n distTraveled: \(distanceTraveledinLatency)")
                    
                    if self.distanceCalc < 0 {
                        self.distanceCalc = 0.01
                    }
                    
                    //if latency is worse than 10s, calculate runnerLoc for pin, else use last known location of runner
                    if self.latencyData.delay > 20 {
                        self.calculateRunnerLocation = true
                        print("simulating runner loc")
                    }
                    else {
                        self.calculateRunnerLocation = false
                        print("NOT simulating runner loc - using last known loc")
                    }
                }
            }
        }
    }
    
    func trackRunner_UI() {
        
        DispatchQueue.main.async {
        
            print("Tracking runner - UI updates")
            
            //1. update distance label & runner pin
            self.updateRunnerInfo()
            self.ETA.isHidden = false
            if self.distanceCalc <= 0 {
                self.ETA.text = "Loading location..."
            }
            else {
                self.ETA.text = String(format: " %d", Int(self.distanceCalc)) + "m away"
            }
        }
        
        DispatchQueue.main.async {
            //2. if nearby, turn distance label red
            if (self.distanceCalc >= 100 && self.distanceCalc <= 150) {
                self.sendLocalNotification(self.runnerName)
               self.ETA.textColor = self.redLabel.textColor
            }
                
            //3. if very close, invalidate timers & segue to cheering
            else if (self.distanceCalc >= 0 && self.distanceCalc < 100) {
                self.runnerTrackerTimer_data.invalidate()
                self.runnerTrackerTimer_UI.invalidate()
                self.userMonitorTimer_data.invalidate()
                self.userMonitorTimer_UI.invalidate()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CheerViewController") as UIViewController
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func updateNearbyRunners_data() {
        
    }
    
    func updateNearbyRunners_UI() {
        
    }
    
    func updateNearbyRunners() {
        
        DispatchQueue.global(qos: .utility).async {
            //find nearby favorite runners and notify if close by
            self.nearbyRunners = NearbyRunners()
            self.nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
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
                                                    DispatchQueue.main.async {
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
                        }
                        
                        self.nearbyTargetRunners = self.optimizedRunners.targetRunners
                    }
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
        
        var coordinate = self.runnerLastLoc
        if self.calculateRunnerLocation {
            coordinate = self.latencyData.calculatedRunnerLoc //TODO: simulated location trajectory isn't great based on 2 loc points, also doesn't reflect race course direction, fine for now assuming they will not have NO connection to update the actual runner location
        }
        
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
