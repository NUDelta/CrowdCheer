//
//  PrerunViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/7/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import MapKit
import Parse

class PrerunViewController: UIViewController {
    
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
        
        //set up view
        start.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        start.enabled = false
        beacon.hidden = true
        beaconLabel.hidden = true
        
        targetPace.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        raceTimeGoal.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        bibNo.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        beacon.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        outfit.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PrerunViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if (targetPace.text != "" || raceTimeGoal.text != "" || bibNo.text != "" || outfit.text != "") {
            start.enabled = true
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
        if (textField == targetPace){
            currUser["targetPace"] = targetPace.text
        }
            
        else if (textField == raceTimeGoal){
            currUser["raceTimeGoal"] = raceTimeGoal.text
        }
            
        else if (textField == bibNo){
            currUser["bibNumber"] = bibNo.text
        }
            
        else if (textField == outfit){
            currUser["outfit"] = outfit.text
        }
        
        currUser.saveInBackground()
        
        if (currUser.valueForKey("targetPace")==nil ||
            currUser.valueForKey("raceTimeGoal")==nil ||
            currUser.valueForKey("bibNumber")==nil ||
            currUser.valueForKey("outfit")==nil) {
                start.enabled = false
        }
        else {
            start.enabled = true
        }
    }
}
