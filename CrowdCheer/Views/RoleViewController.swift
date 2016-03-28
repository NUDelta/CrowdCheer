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
        
        self.locationMgr.requestAlwaysAuthorization()
        self.locationMgr.requestWhenInUseAuthorization()
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
}
