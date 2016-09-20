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
    @IBOutlet weak var outfit: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var runnerMonitor: RunnerMonitor = RunnerMonitor()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up view
        saveButton.enabled = false
        
        targetPace.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        raceTimeGoal.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        bibNo.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        outfit.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PrerunViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if (targetPace.text != "" || raceTimeGoal.text != "" || bibNo.text != "" || outfit.text != "") {
            saveButton.enabled = true
        }
        
        runnerMonitor = RunnerMonitor()
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
                saveButton.enabled = false
        }
        else {
            saveButton.enabled = true
        }
    }
}
