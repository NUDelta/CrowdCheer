//
//  ProfileViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/8/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import MapKit
import Parse

class ProfileViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var user: PFUser = PFUser()
    
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var profilePicView: UIImageView!
    @IBOutlet weak var updatePicture: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func cheerCommitment(sender: UIButton) {
        //call a function that will save a "cheer" object to parse, that keeps track of the runner:cheerer pairing
        
    }
}

