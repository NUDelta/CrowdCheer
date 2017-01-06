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
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var lookBanner: UILabel!
    @IBOutlet weak var cheerBanner: UILabel!
    @IBOutlet weak var nearBanner: UILabel!
    
    var userMonitorTimer: NSTimer = NSTimer()
    var runnerTrackerTimer: NSTimer = NSTimer()
    var interval: Int = Int()
    var spectator: PFUser = PFUser.currentUser()!
    var spectatorName: String = ""
    var runner: PFUser = PFUser()
    var runnerName: String = ""
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFilePath: NSURL = NSURL()
    var audioFileName: String = ""
    var contextPrimer = ContextPrimer()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var verifiedDelivery: VerifiedDelivery = VerifiedDelivery()
    var verifiedReceival: VerifiedReceival = VerifiedReceival()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spectatorName = spectator.username!
        distanceLabel.hidden = true
        nearBanner.hidden = false
        nearBanner.text = "Loading location..."
        lookBanner.hidden = true
        cheerBanner.hidden = true
        
        //update the runner profile info & notify
        getRunnerProfile()
        interval = 1
        
        //every second, update the distance and map with the runner's location
        runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(CheerViewController.trackRunner), userInfo: nil, repeats: true)
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(CheerViewController.monitorUser), userInfo: nil, repeats: true)
        contextPrimer = ContextPrimer()
        spectatorMonitor = SpectatorMonitor()
        verifiedDelivery = VerifiedDelivery()
        verifiedReceival = VerifiedReceival()
        
        
        //begin recording audio
//        verifiedDelivery.audioRecorder.delegate = self //crashes here
        startRecordingSpectatorAudio(runnerName, spectatorName: spectatorName)
        
        
    }
    
    func monitorUser() {
        
        //start spectator tracker
        spectatorMonitor.monitorUserLocation()
        spectatorMonitor.updateUserLocation()
        spectatorMonitor.updateUserPath(interval)
        
        if UIApplication.sharedApplication().applicationState == .Background {
            print("app status: \(UIApplication.sharedApplication().applicationState)")
            
            spectatorMonitor.enableBackgroundLoc()
        }
    }
    
    func trackRunner() {
        //get latest loc and update map and distance label
        
        print("Tracking runner")
    
        contextPrimer.getRunnerLocation(runner) { (runnerLoc) -> Void in
            
            self.runnerLastLoc = runnerLoc
        }
        
        let actualTime = contextPrimer.actualTime
        let setTime = contextPrimer.setTime
        let getTime = contextPrimer.getTime
        let showTime = NSDate()
        let latencyData = contextPrimer.handleLatency(runner, actualTime: actualTime, setTime: setTime, getTime: getTime, showTime: showTime)
        
        if (runnerLastLoc.latitude == 0.0 && runnerLastLoc.longitude == 0.0) {
            print("skipping coordinate")
        }
        else {
            runnerPath.append(runnerLastLoc)
            let runnerCLLoc = CLLocation(latitude: runnerLastLoc.latitude, longitude: runnerLastLoc.longitude)
            let distanceLast = (contextPrimer.locationMgr.location!.distanceFromLocation(runnerCLLoc))
            var distanceCalc = distanceLast - contextPrimer.calculateDistTraveled(latencyData.delay, speed: contextPrimer.speed)
            if distanceCalc < 0 {
                distanceCalc = 0.01
            }
            
            updateBanner(runnerCLLoc)
            distanceLabel.text = String(format: " %.02f", distanceCalc) + "m away"
        }
    }
    
    func getRunnerProfile() {
        
        runner = contextPrimer.getRunner()
            //update runner name, bib #, picture
            runnerName = (runner.valueForKey("name"))! as! String
            let runnerBib = (runner.valueForKey("bibNumber"))!
            let runnerOutfit = (runner.valueForKey("outfit"))!
            let userImageFile = runner["profilePic"] as? PFFile
            userImageFile!.getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
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
            nearBanner.text = runnerName + " is nearby!"
    }
    
    func updateBanner(location: CLLocation) {
        
        let distanceCurr = (contextPrimer.locationMgr.location!.distanceFromLocation(location))
        if runnerPath.count > 1 {
            let coordinatePrev = runnerPath[runnerPath.count-2]
            let locationPrev = CLLocation(latitude: coordinatePrev.latitude, longitude: coordinatePrev.longitude)
            let distancePrev = (contextPrimer.locationMgr.location!.distanceFromLocation(locationPrev))
            
            if distancePrev >= distanceCurr {
                
                if distanceCurr>75 {
                    nearBanner.text = runnerName + " is nearby!"
                    nearBanner.hidden = false
                    lookBanner.hidden = true
                    cheerBanner.hidden = true
                }
                    
                else if distanceCurr<=75 && distanceCurr>40 {
                    lookBanner.text = "LOOK FOR " + runnerName.uppercaseString + "!"
//                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    nearBanner.hidden = true
                    lookBanner.hidden = false
                    cheerBanner.hidden = true
                }
                    
                else if distanceCurr<=40 {
                    cheerBanner.text = "CHEER FOR " + runnerName.uppercaseString + "!"
                    nearBanner.hidden = true
                    lookBanner.hidden = true
                    cheerBanner.hidden = false
                    
                }
                    
                else {
                    nearBanner.text = runnerName + " is nearby!"
                    nearBanner.hidden = false
                    lookBanner.hidden = true
                    cheerBanner.hidden = true
                }
            }
                
            else if distancePrev < distanceCurr {
                //runner is moving away
                
                if distanceCurr <= 20 {
                    //if error in location, add 20m buffer for cheering
                    cheerBanner.text = "CHEER FOR " + runnerName.uppercaseString + "!"
                    nearBanner.hidden = true
                    lookBanner.hidden = true
                    cheerBanner.hidden = false
                }
                
                else if distanceCurr>50 {
                    nearBanner.text = runnerName + " has passed by."
                    nearBanner.hidden = false
                    lookBanner.hidden = true
                    cheerBanner.hidden = true
                    
                    runnerTrackerTimer.invalidate()
                    userMonitorTimer.invalidate()
                    verifyCheeringAlert()
                }
            }
                
            else {
                nearBanner.hidden = true
                lookBanner.hidden = true
                cheerBanner.hidden = true
            }

        }
        
        else {
            nearBanner.text = runnerName + " is nearby!"
            nearBanner.hidden = false
            lookBanner.hidden = true
            cheerBanner.hidden = true
        }
    }
    
    func startRecordingSpectatorAudio(runnerName: String, spectatorName: String) {
        
        //initialize recording session
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission({ (allowed) in
                if allowed {
                    print("recording permission granted")
                } else {
                    print("ERROR: permission denied for audio")
                }
            })
        }
            
        catch {
            print("ERROR: error initializing audio")
        }
        
        //start recording
        audioFileName = spectatorName + "_" + runnerName + ".m4a"
        audioFilePath = verifiedDelivery.getDocumentsDirectory().URLByAppendingPathComponent(audioFileName)!
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: audioFilePath, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
        }
        catch {
            print("ERROR: error recording audio")
        }
    }
    
    func verifyCheeringAlert() {
        let alertTitle = "Thank you for supporting " + runnerName + "!"
        let alertMessage = "Did you spot and cheer for " + runnerName + "?"
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Yes, I did!", style: UIAlertActionStyle.Default, handler: didCheer))
        alertController.addAction(UIAlertAction(title: "No, I missed them.", style: UIAlertActionStyle.Default, handler: didNotCheer))
        
        presentViewController(alertController, animated: true, completion: nil)
        
        //stop recording audio
        audioRecorder.stop()
    }
    
    func didCheer(alert: UIAlertAction!) {
        
        //verify cheer & reset pair
        verifiedDelivery.spectatorDidCheer(runner, didCheer: true, audioFilePath: audioFilePath, audioFileName: audioFileName)
        contextPrimer.resetRunner()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("DashboardViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
        //save didCheer in Cheers as true
    }
    
    func didNotCheer(alert: UIAlertAction!) {
        
        //verify cheer & reset pair
        verifiedDelivery.spectatorDidCheer(runner, didCheer: false, audioFilePath: audioFilePath, audioFileName: audioFileName)
        contextPrimer.resetRunner()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("DashboardViewController") as UIViewController
        navigationController?.pushViewController(vc, animated: true)
        //save didCheer in Cheers as false
    }
}
