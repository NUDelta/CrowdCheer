//
//  AffinityViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 6/3/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import UIKit
import Foundation
import MapKit
import Parse

class AffinityViewController: UIViewController {
    
    var spectator: PFUser = PFUser.currentUser()!
    
    @IBOutlet weak var bibNo: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var prestartDate: NSDate = NSDate()
    var prestartTimer: NSTimer = NSTimer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //set up rules for keyboard
        bibNo.addTarget(self, action: #selector(AffinityViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AffinityViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
//        prestartDate = dateFormatter.dateFromString(prestartDateString)! //hardcoded x min before race
//        prestartTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(AffinityViewController.sendLocalNotification_prestart), userInfo: nil, repeats: false)
    }
    
    //keyboard behavior
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChange(textField: UITextField) {
        //save profile info to Parse
        let currUser = PFUser.currentUser()
        if (textField == bibNo){
            currUser!["targetRunnerBib"] = bibNo.text
        }
        
        currUser!.saveInBackground()
    }
    
//    func sendLocalNotification_prestart() {
//        let localNotification = UILocalNotification()
//        localNotification.alertBody = "Try tracking your runner before the race starts! Go to the Race Dashboard to see runners. If you don't see them yet, remind them to set up their app."
//        localNotification.soundName = UILocalNotificationDefaultSoundName
//        localNotification.timeZone = NSTimeZone.defaultTimeZone()
//        localNotification.fireDate = prestartDate
//        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
//        
//        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
//    }
}
