//
//  DashboardViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 8/24/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import Parse

class DashboardViewController: UIViewController {
    
    var runner: PFUser = PFUser()
    var runnerPic: UIImage = UIImage()
    var runnerName: String = ""
    var runnerBib: String = ""
    
    var userMonitorTimer: NSTimer = NSTimer()
    var nearbyRunnersTimer: NSTimer = NSTimer()
    var areRunnersNearby: Bool = Bool()
    var interval: Int = Int()
    var spectatorMonitor: SpectatorMonitor = SpectatorMonitor()
    var nearbyRunners: NearbyRunners = NearbyRunners()
    var optimizedRunners: OptimizedRunners = OptimizedRunners()
    var selectedRunners: SelectedRunners = SelectedRunners()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        spectatorMonitor = SpectatorMonitor()
        optimizedRunners = OptimizedRunners()
        areRunnersNearby = false
        interval = 30
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
        updateNearbyRunners()
        
        userMonitorTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.monitorUser), userInfo: nil, repeats: true)
        nearbyRunnersTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(DashboardViewController.updateNearbyRunners), userInfo: nil, repeats: true)
        
    }

    override func viewWillDisappear(animated: Bool) {
        userMonitorTimer.invalidate()
        nearbyRunnersTimer.invalidate()
        
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
    
    func updateNearbyRunners() {
        //every x seconds, update array of nearby runners and display those runners
        
        var runnerCount = 0
        var targetRunnerTrackingStatus = self.optimizedRunners.targetRunners
        
        
        nearbyRunners = NearbyRunners()
        nearbyRunners.checkProximityZone(){ (runnerLocations) -> Void in
            
            if ((runnerLocations?.isEmpty) == true) {
                self.areRunnersNearby = false
            }
            else {
                self.areRunnersNearby = true
            }
            
            //R+R* Condition
            self.optimizedRunners.considerAffinity(runnerLocations!) { (affinities) -> Void in
                print("affinities \(affinities)")
                
                for (runner, runnerLoc) in runnerLocations! {
                    
                    let runnerLastLoc = CLLocationCoordinate2DMake(runnerLoc.latitude, runnerLoc.longitude)
                    let runnerCoord = CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)
                    let dist = runnerCoord.distanceFromLocation(self.optimizedRunners.locationMgr.location!)
                    print(runner.username, dist)
                    
                    for affinity in affinities {
                        
                        var isTargetRunnerNear = false
                        if runner == affinity.0 {
                            //Goal: Show target runners throughout the race
                            if dist > 400 { //if runner is more than 2km away (demo: 400)
                                if affinity.1 == 10 { //if target runner, display runner
                                    //TODO: display target runner
                                    targetRunnerTrackingStatus[runner.objectId] = true
                                    runnerCount += 1
                                }
                                else if affinity.1 != 10 { //if general runner, don't add them yet
                                    //do nothing
                                }
                            }
                                
                                //Goal: Show all runners near me, including target runners
                            else if dist > 200 && dist <= 400 { //if runner is between 1-2km away (demo: 200-400)
                                if affinity.1 == 10 { //if target runner, add them to the map
                                    //TODO: display target runner
                                    targetRunnerTrackingStatus[runner.objectId] = true
                                    runnerCount += 1
                                }
                                else if affinity.1 != 10 { //if general runner, also add them to the map
                                    //TODO: display general runner
                                    runnerCount += 1
                                    self.sendLocalNotification_any()
                                }
                            }
                                
                                //Goal: If target runner is close, only show them. If not, then continue to show all runners
                            else if dist <= 200 { //if runner is less than 1km away (demo: 200)
                                if affinity.1 == 10 { //if target runner, add them to the map & notify
                                    //TODO: display target runner
                                    targetRunnerTrackingStatus[runner.objectId] = true
                                    runnerCount += 1
                                    let name = runner.valueForKey("name") as! String
                                    self.sendLocalNotification_target(name)
                                    isTargetRunnerNear = true
                                }
                                else if affinity.1 != 10 { //if general runner, check if target runner is nearby
                                    if !isTargetRunnerNear {
                                        //TODO: display general runner
                                        runnerCount += 1
                                    }
                                }
                            }
                        }
                    }
                }
                //if target runners are not showing up, notify target runners to start tracking
                self.notifyTargetRunners(targetRunnerTrackingStatus)
                
                self.nearbyRunners.saveRunnerCount(runnerCount)
            }
            
            //            //TESTING//
            //            self.optimizedRunners.considerConvenience(runnerLocations!) { (conveniences) -> Void in
            //                print("conveniences \(conveniences)")
            //            }
            //
            //            self.optimizedRunners.considerNeed(runnerLocations!) { (needs) -> Void in
            //                print("needs \(needs)")
            //            }
        }
        
        
    }
    
    func sendLocalNotification_any() {
        if areRunnersNearby == true {
            
            if UIApplication.sharedApplication().applicationState == .Background {
                let localNotification = UILocalNotification()
                localNotification.alertBody = "Cheer for runners near you!"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                
                UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
            }
        }
            
        else {
            print("local notification: no runners nearby")
        }
    }
    
    func sendLocalNotification_target(name: String) {
        
        if UIApplication.sharedApplication().applicationState == .Background {
            
            let localNotification = UILocalNotification()
            localNotification.alertBody =  name + " is near you, get ready to cheer!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
            
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        }
            
        else if UIApplication.sharedApplication().applicationState == .Active {
            
            let alertTitle = name + " is nearby!"
            let alertController = UIAlertController(title: alertTitle, message: "Get ready to cheer!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func notifyTargetRunners(targetRunnersStatus: [String: Bool]) {
        
        var runner: PFUser
        
        for targetRunner in targetRunnersStatus {
            if targetRunner.1 == false {
                runner = PFQuery.getUserObjectWithId(targetRunner.0)
                let name = runner.valueForKey("name") as! String
                
                if UIApplication.sharedApplication().applicationState == .Background {
                    
                    let localNotification = UILocalNotification()
                    localNotification.alertBody =  name + "'s phone isn't active! Call or text to remind them to use the app!"
                    localNotification.soundName = UILocalNotificationDefaultSoundName
                    localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
                    
                    UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
                }
                    
                else if UIApplication.sharedApplication().applicationState == .Active {
                    
                    let alertTitle = name + "'s phone isn't active!"
                    let alertController = UIAlertController(title: alertTitle, message: "You won't see your runners if their phones aren't active. Call or text them to remind them to use the app!", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "Call", style: UIAlertActionStyle.Default, handler: openPhone))
                    alertController.addAction(UIAlertAction(title: "Text", style: UIAlertActionStyle.Default, handler: openMessages))
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                
            }
        }
    }

    func openPhone(alert: UIAlertAction!) {
        UIApplication.sharedApplication().openURL(NSURL(string:"tel:1")!)
    }
    
    func openMessages(alert: UIAlertAction!) {
        UIApplication.sharedApplication().openURL(NSURL(string:"sms:")!)
    }

}