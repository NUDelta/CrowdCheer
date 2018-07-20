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
    
    var spectator: PFUser = PFUser.current()!
    
    @IBOutlet weak var bibNo: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var prestartDate: Date = Date()
    var prestartTimer: Timer = Timer()
    
    //TODO: add view event logging
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //set up rules for keyboard
        bibNo.addTarget(self, action: #selector(AffinityViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AffinityViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //get fave bibs if any
        if spectator.value(forKey: "targetRunnerBib") == nil {
            //don't retrieve pace
        }
        else {
            let targetRunnerBib = (spectator.value(forKey: "targetRunnerBib"))! as! String
            bibNo.text = targetRunnerBib
        }
        
    }
    
    //keyboard behavior
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        //save profile info to Parse
        let currUser = PFUser.current()
        if (textField == bibNo){
            currUser!["targetRunnerBib"] = bibNo.text
        }
        
        currUser!.saveInBackground()
    }
    
}
