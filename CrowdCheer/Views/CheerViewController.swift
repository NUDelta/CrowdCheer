//
//  CheerViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/17/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import MapKit
import Parse
import AudioToolbox
import AVFoundation

class CheerViewController: UIViewController, AVAudioRecorderDelegate {
    

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bibLabel: UILabel!
    @IBOutlet weak var outfit: UILabel!
    @IBOutlet weak var cheer: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var lookBanner: UILabel!
    @IBOutlet weak var cheerBanner: UILabel!
    @IBOutlet weak var nearBanner: UILabel!
    
    var userMonitorTimer_data: Timer = Timer()
    var userMonitorTimer_UI: Timer = Timer()
    var runnerTrackerTimer_data: Timer = Timer()
    var runnerTrackerTimer_UI: Timer = Timer()
    var nearbyRunnersTimer: Timer = Timer()
    var verifyCheersTimer: Timer = Timer()
    
    var interval: Int = Int()
    var spectator: PFUser = PFUser.current()!
    var spectatorName: String = ""
    var myLocation = CLLocation()
    var runner: PFUser = PFUser()
    var runnerName: String = ""
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerDistances: Array<Double> = []
    var latencyData: (delay: TimeInterval, calculatedRunnerLoc: CLLocationCoordinate2D) = (0.0, CLLocationCoordinate2D())
    var distanceCalc: Double = Double()
    var audioRecorder: AVAudioRecorder!
    var audioFilePath: NSURL = NSURL()
    var audioFileName: String = ""
    var runnerLocations = [PFUser: PFGeoPoint]()
    var nearbyTargetRunners = [String: Bool]()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var contextPrimer: ContextPrimer = ContextPrimer()
    var verifiedDelivery: VerifiedDelivery = VerifiedDelivery()
    var verifiedReceival: VerifiedReceival = VerifiedReceival()
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "CheerVC"
    
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
        verifyCheersTimer.invalidate()
        
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
        spectatorName = spectator.username!
        distanceLabel.isHidden = true
        nearBanner.isHidden = false
        nearBanner.text = "Loading location..."
        lookBanner.isHidden = true
        cheerBanner.isHidden = true
        
        //update the runner profile info & notify
        getRunnerProfile()
        distanceCalc = -1
        interval = 1
        
        //tracking runner -- data + UI timers
        runnerTrackerTimer_data = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(CheerViewController.trackRunner_data), userInfo: nil, repeats: true)
        runnerTrackerTimer_UI = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(CheerViewController.trackRunner_UI), userInfo: nil, repeats: true)
        
        //monitoring spectator -- data + UI timers
        userMonitorTimer_data = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(CheerViewController.monitorUser_data), userInfo: nil, repeats: true)
        userMonitorTimer_UI = Timer.scheduledTimer(timeInterval: Double(interval), target: self, selector: #selector(CheerViewController.monitorUser_UI), userInfo: nil, repeats: true)
        
        optimizedRunners = OptimizedRunners()
        contextPrimer = ContextPrimer()
        spectatorMonitor = SpectatorMonitor()
        verifiedDelivery = VerifiedDelivery()
        verifiedReceival = VerifiedReceival()
        
        
        //begin recording audio
        startRecordingSpectatorAudio(runnerName, spectatorName: spectatorName)
        
    }
    
    func monitorUser_data() {
        
        DispatchQueue.global(qos: .utility).async {
            //start spectator tracker
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
    
    func trackRunner_data() {
        DispatchQueue.global(qos: .utility).async {
            print("Tracking runner - data - cheerVC")
            
            //1. get most recent runner locations
            if self.contextPrimer.locationMgr.location != nil {
                self.myLocation = self.contextPrimer.locationMgr.location!
            }
            else {
                //do nothing
            }
            
            self.contextPrimer.getRunnerLocation(self.runner) { (runnerLoc) -> Void in
                
                DispatchQueue.global(qos: .utility).async {
                    print("getrunnerloc callback running - cheerVC")
                    self.runnerLastLoc = runnerLoc //TODO: when no data as you transition from TrackVC to CheerVC, runnerLastLoc is 0,0 and the calc dist traveled is 0.0, so Cheer stages don't progress
                }
            }
            print(" runnerlastloc - cheerVC: \(self.runnerLastLoc) \n ")
            
            //2. calculate latency data
            let actualTime = self.contextPrimer.actualTime
            let setTime = self.contextPrimer.setTime
            let getTime = self.contextPrimer.getTime
            let showTime = Date()
            self.latencyData = self.contextPrimer.handleLatency(self.runner, actualTime: actualTime, setTime: setTime, getTime: getTime, showTime: showTime)
            
            //3. calculate distance between spectator & runner using current latency
            if(CLLocationCoordinate2DIsValid(self.runnerLastLoc)) {
                if (self.runnerLastLoc.latitude != 0.0 && self.runnerLastLoc.longitude != 0.0) {
                    
                    //convert to CLLocation
                    let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
                    
                    //store last known distance between spectator & runner
                    let distanceLast = (self.myLocation.distance(from: runnerCLLoc))
                    
                    //calculate the simulated distance traveled during the delay (based on speed + delay)
                    let distanceTraveledinLatency = self.contextPrimer.calculateDistTraveled(self.latencyData.delay, speed: self.contextPrimer.speed)
                    
                    //subtract the simulated distance traveled during the delay (based on speed + delay) from the last known distance from spectator to give us an updated distance from spectator
                    self.distanceCalc = distanceLast -  distanceTraveledinLatency
                    
                    print(" cheerVC: \n distfromMeCalc: \(self.distanceCalc) \n distLast: \(distanceLast) \n distTraveled: \(distanceTraveledinLatency)")
                    
                    if self.distanceCalc < 0 {
                        self.distanceCalc = self.distanceCalc * -1
                    }
                    
                    //append to runner distances
                    self.runnerDistances.append(self.distanceCalc)
                }
            }
        }
    }
    
    func trackRunner_UI() {
        DispatchQueue.main.async {
            self.updateBanner(self.distanceCalc)
            self.distanceLabel.text = String(format: " %.02f", self.distanceCalc) + "m away"
        }
    }
    
    func getRunnerProfile() {
        if(contextPrimer.getRunner().username != nil) {
            runner = contextPrimer.getRunner()
        }
            //update runner name, bib #, picture, outfit, and cheer
            runnerName = (runner.value(forKey: "name"))! as! String
            let runnerBib = (runner.value(forKey: "bibNumber"))!
            let runnerOutfit = (runner.value(forKey: "outfit"))!
            let runnerCheer = (runner.value(forKey: "cheer"))!
            let userImageFile = runner["profilePic"] as? PFFile
            userImageFile!.getDataInBackground {
                (imageData: Data?, error: Error?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        let image = UIImage(data:imageData)
                        self.profilePic.image = image
                    }
                }
            }
            nameLabel.text = runnerName
            bibLabel.text = "Bib #: " + (runnerBib as! String)
            outfit.text = "Wearing: " + (runnerOutfit as! String)
            cheer.text = "Cheer: '" + (runnerCheer as! String) + "'"
            nearBanner.text = runnerName + " is nearby!"
    }
    
    func updateBanner(_ distanceCurr: Double) {
        
        if runnerDistances.count > 2 {
            let distancePrev = runnerDistances[runnerDistances.count-3]
            
            print("distPrev: \(distancePrev)")
            print("distCurr: \(distanceCurr)")
            
            
            if distancePrev >= distanceCurr {
                //running is moving towards
                
                if distanceCurr>75 {
                    nearBanner.text = runnerName + " is nearby!"
                    nearBanner.isHidden = false
                    lookBanner.isHidden = true
                    cheerBanner.isHidden = true
                }
                    
                else if distanceCurr<=75 && distanceCurr>40 {
                    lookBanner.text = "LOOK FOR " + runnerName.uppercased() + "!"
                    //                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    nearBanner.isHidden = true
                    lookBanner.isHidden = false
                    cheerBanner.isHidden = true
                }
                    
                else if distanceCurr<=40 {
                    cheerBanner.text = "CHEER FOR " + runnerName.uppercased() + "!"
                    nearBanner.isHidden = true
                    lookBanner.isHidden = true
                    cheerBanner.isHidden = false
                    
                }
                    
                else {
                    nearBanner.text = runnerName + " is nearby!"
                    nearBanner.isHidden = false
                    lookBanner.isHidden = true
                    cheerBanner.isHidden = true
                }
            }
                
            else if distancePrev < distanceCurr {
                //runner is moving away
                
                if distanceCurr <= 20 {
                    //if error in location, add 20m buffer for cheering
                    cheerBanner.text = "CHEER FOR " + runnerName.uppercased() + "!"
                    nearBanner.isHidden = true
                    lookBanner.isHidden = true
                    cheerBanner.isHidden = false
                }
                    
                else if distanceCurr >= 50  {
                    nearBanner.text = runnerName + " has passed by."
                    nearBanner.isHidden = false
                    lookBanner.isHidden = true
                    cheerBanner.isHidden = true
                    
                    runnerTrackerTimer_data.invalidate()
                    runnerTrackerTimer_UI.invalidate()
                    userMonitorTimer_data.invalidate()
                    userMonitorTimer_UI.invalidate()
                    verifyCheeringAlert()
                    verifyCheersTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(verifyCheeringAlert), userInfo: nil, repeats: false)
                    nearbyRunnersTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
                    
                }
            }
                
            else {
                nearBanner.isHidden = true
                lookBanner.isHidden = true
                cheerBanner.isHidden = true
            }
            
        }
            
        else {
            nearBanner.text = runnerName + " is nearby!"
            nearBanner.isHidden = false
            lookBanner.isHidden = true
            cheerBanner.isHidden = true
        }
    }
    
    func startRecordingSpectatorAudio(_ runnerName: String, spectatorName: String) {
        
        //start recording
        audioFileName = spectatorName + "_" + runnerName + ".m4a"
        audioFilePath = verifiedDelivery.getDocumentsDirectory().appendingPathComponent(audioFileName)! as NSURL
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath as URL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
        }
        catch {
            print("ERROR: error recording audio")
        }
    }
    
    func verifyCheeringAlert() {
        
        if UIApplication.shared.applicationState == .background {
            
            let localNotification = UILocalNotification()
            let notificationID = arc4random_uniform(10000000)
            
            var spectatorInfo = [String: AnyObject]()
            spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
            spectatorInfo["source"] = "cheer_verifyCheerNotification" as AnyObject
            spectatorInfo["notificationID"] = notificationID as AnyObject
            spectatorInfo["receivedNotification"] = true as AnyObject
            spectatorInfo["receivedNotificationTimestamp"] = Date() as AnyObject
            
            localNotification.alertBody =  "Did you spot and cheer for " + runnerName + "?"
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
        
        let alertTitle = "Thank you for supporting " + runnerName + "!"
        let alertMessage = "Did you spot and cheer for " + runnerName + "?"
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Yes, I did!", style: UIAlertActionStyle.default, handler: didCheer))
        alertController.addAction(UIAlertAction(title: "No, I missed them.", style: UIAlertActionStyle.default, handler: didNotCheer))
        
        present(alertController, animated: true, completion: nil)
        
        //stop recording audio
        audioRecorder.stop()
    }
    
    func didCheer(_ alert: UIAlertAction!) {
        
        nearbyRunnersTimer.invalidate()
        
        
        //verify cheer & reset pair
        verifiedDelivery.spectatorDidCheer(runner, didCheer: true, audioFilePath: audioFilePath, audioFileName: audioFileName)
        contextPrimer.resetRunner()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DashboardViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
        //save didCheer in Cheers as true
        
        verifyCheersTimer.invalidate()
    }
    
    func didNotCheer(_ alert: UIAlertAction!) {
        
        nearbyRunnersTimer.invalidate()
        
        //verify cheer & reset pair
        verifiedDelivery.spectatorDidCheer(runner, didCheer: false, audioFilePath: audioFilePath, audioFileName: audioFileName)
        contextPrimer.resetRunner()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DashboardViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
        //save didCheer in Cheers as false
        
        verifyCheersTimer.invalidate()
    }
    
    func sendLocalNotification_target(_ name: String) {
        
        if UIApplication.shared.applicationState == .background {
            
            let localNotification = UILocalNotification()
            let notificationID = arc4random_uniform(10000000)
            
            var spectatorInfo = [String: AnyObject]()
            spectatorInfo["spectator"] = PFUser.current()!.objectId as AnyObject
            spectatorInfo["source"] = "cheer_targetRunnerNotification" as AnyObject
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
    }
}
