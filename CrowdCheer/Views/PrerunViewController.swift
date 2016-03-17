//
//  PrerunViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/7/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import MapKit
import Parse

class PrerunViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var runner: PFUser = PFUser.currentUser()
    
    
    @IBOutlet weak var targetPace: UITextField!
    @IBOutlet weak var raceTimeGoal: UITextField!
    @IBOutlet weak var bibNo: UITextField!
    @IBOutlet weak var beacon: UITextField!
    @IBOutlet weak var beaconLabel: UILabel!
    @IBOutlet weak var outfit: UITextField!
    @IBOutlet weak var start: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
        
        self.start.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        self.start.enabled = false
        self.beacon.hidden = true
        self.beaconLabel.hidden = true
        
        targetPace.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        raceTimeGoal.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        bibNo.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        beacon.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        outfit.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        if (targetPace.text != "" || raceTimeGoal.text != "" || bibNo.text != "" || outfit.text != "") {
            self.start.enabled = true
        }
        
        
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
        if (textField == self.targetPace){
            currUser["targetPace"] = self.targetPace.text
        }
            
        else if (textField == self.raceTimeGoal){
            currUser["raceTimeGoal"] = self.raceTimeGoal.text
        }
            
        else if (textField == self.bibNo){
            currUser["bibNumber"] = self.bibNo.text
        }
            
        else if (textField == self.outfit){
            currUser["outfit"] = self.outfit.text
        }
        
        currUser.saveInBackground()
        
        if (currUser.valueForKey("targetPace")==nil ||
            currUser.valueForKey("raceTimeGoal")==nil ||
            currUser.valueForKey("bibNumber")==nil ||
            currUser.valueForKey("outfit")==nil) {
                self.start.enabled = false
        }
        else {
            self.start.enabled = true
        }
    }
}
