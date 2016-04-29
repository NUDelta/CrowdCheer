//
//  RoleViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/22/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import Parse

class RoleViewController: UIViewController {
    
    @IBOutlet weak var running: UIButton!
    @IBOutlet weak var cheering: UIButton!
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var user: PFUser = PFUser.currentUser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationMgr.requestAlwaysAuthorization()
        locationMgr.requestWhenInUseAuthorization()
        
        if isWiFiConnected()==false {
            turnOnWiFiAlert()
        }
        user = PFUser.currentUser()
    }
    
    
    //Set user's role as runner
    @IBAction func running(sender: UIButton) {
        user["role"] = "runner"
        user.saveInBackground()
        print(user.valueForKey("role")!)
        self.performSegueWithIdentifier("run", sender: nil)
    }
    
    
    //Set user's role as spectator
    @IBAction func cheering(sender: UIButton) {
        user["role"] = "cheerer"
        user.saveInBackground()
        print(user.valueForKey("role")!)
        self.performSegueWithIdentifier("cheer", sender: nil)
    }
    
    
    //Prompt user to turn on WiFi
    func turnOnWiFiAlert() {
        let alertTitle = "Location Accuracy"
        let alertController = UIAlertController(title: alertTitle, message: "Turning on your Wi-Fi is required for accurate location data.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Go to Wi-Fi Settings", style: UIAlertActionStyle.Default, handler: openSettings))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func openSettings(alert: UIAlertAction!) {
        UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=WIFI")!)
    }
    
    func isWiFiConnected() -> Bool {
        
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return false
        }
        
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                print("Reachable via WiFi")
                return true
            } else {
                print("Reachable via Cellular")
                return false
            }
        } else {
            print("Network not reachable")
            return false
        }
    }
}
