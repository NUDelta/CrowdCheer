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
    
    var spectator: PFUser = PFUser.currentUser()
    
    @IBOutlet weak var bibNo: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //set up rules for keyboard
        bibNo.addTarget(self, action: #selector(AffinityViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AffinityViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
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
            currUser["targetRunnerBib"] = bibNo.text
        }
        
        currUser.saveInBackground()
    }
}
