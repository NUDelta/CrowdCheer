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
    @IBOutlet weak var editProfile: UIBarButtonItem!
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var user: PFUser = PFUser.currentUser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationMgr.requestAlwaysAuthorization()
        locationMgr.requestWhenInUseAuthorization()
        
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
    
    @IBAction func editProfile(sender: UIBarButtonItem) {
        let sb = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        var controllers =  self.navigationController?.viewControllers
        let profileView = sb.instantiateViewControllerWithIdentifier("ProfileViewController")
        let prerunView = sb.instantiateViewControllerWithIdentifier("prerunViewController")
        controllers?.append(prerunView)
        controllers?.append(profileView)
        self.navigationController?.setViewControllers(controllers!, animated: true)
//        self.presentViewController(profileView, animated: true, completion: nil)
    }
}
