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
    
    @IBOutlet weak var roleButton: UISegmentedControl!
    @IBOutlet weak var nextButton: UIBarButtonItem!

    
    let locationMgr: CLLocationManager = CLLocationManager()
    var user: PFUser = PFUser.currentUser()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationMgr.requestAlwaysAuthorization()
        locationMgr.requestWhenInUseAuthorization()
        
        user = PFUser.currentUser()!
        getProfileInfo()
        
        let font = UIFont.systemFontOfSize(20)
        roleButton.setTitleTextAttributes([NSFontAttributeName: font],
                                          forState: UIControlState.Normal)
        roleButton.selected = false
        
    }
    
    
    func getProfileInfo() {
        
        var role: String
        
        
        if user.valueForKey("role") == nil {
            //don't retrieve role
        }
        else {
            role = (user.valueForKey("role"))! as! String
            if role == "runner" {
                roleButton.selectedSegmentIndex = 0
            }
            else {
                roleButton.selectedSegmentIndex = 1
            }
        }
    }
    
    @IBAction func selectRole(sender:UISegmentedControl) {
        switch roleButton.selectedSegmentIndex {
        case 0:
            user["role"] = "runner"
            user.saveInBackground()
            
        case 1:
            user["role"] = "cheerer"
            user.saveInBackground()
            
        default:
            break
        }
    }
    
    @IBAction func saveRole(sender: UIBarButtonItem) {
        switch roleButton.selectedSegmentIndex {
        case 0:
            self.performSegueWithIdentifier("run", sender: nil)
        case 1:
            self.performSegueWithIdentifier("cheer", sender: nil)
        default:
            break
        }
        
    }
}
