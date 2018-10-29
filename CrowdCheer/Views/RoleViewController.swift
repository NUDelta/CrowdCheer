//
//  RoleViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/22/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import Parse
import AVFoundation

class RoleViewController: UIViewController {
    
    @IBOutlet weak var roleButton: UISegmentedControl!
    @IBOutlet weak var nextButton: UIBarButtonItem!

    
    let locationMgr: CLLocationManager = CLLocationManager()
    var user: PFUser?
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "RoleVC"
    
    override func viewDidAppear(_ animated: Bool) {
        
        viewWindowID = String(arc4random_uniform(10000000))
        
        let newViewWindowEvent = PFObject(className: "ViewWindows")
        if let currentUser = PFUser.current() {
            newViewWindowEvent["userID"] = currentUser.objectId as AnyObject
        }
        newViewWindowEvent["vcName"] = vcName as AnyObject
        newViewWindowEvent["viewWindowID"] = viewWindowID as AnyObject
        newViewWindowEvent["viewWindowEvent"] = "segued to" as AnyObject
        newViewWindowEvent["viewWindowTimestamp"] = Date() as AnyObject
        newViewWindowEvent.saveInBackground(block: (
            {(success: Bool, error: Error?) -> Void in
                if (!success) {
                    print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                    newViewWindowEvent.saveEventually()
                }
        })
        )
        
        var viewWindowDict = [String: String]()
        viewWindowDict["vcName"] = vcName
        viewWindowDict["viewWindowID"] = viewWindowID
        appDel.set(viewWindowDict, forKey: viewWindowDictKey)
        appDel.synchronize()
        
        if let currUser = PFUser.current() {
            user = currUser
            getProfileInfo()
            
        }
        else {
            self.performSegue(withIdentifier: "showLogin", sender: nil)
        }
    }
    
    @IBAction func logOutCurrentUser(_ sender: Any) {
        PFUser.logOut()
        nextButton.isEnabled = false
        self.performSegue(withIdentifier: "showLogin", sender: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        let newViewWindow = PFObject(className: "ViewWindows")
        if let currentUser = PFUser.current() {
            newViewWindow["userID"] = currentUser.objectId as AnyObject
        }
        newViewWindow["vcName"] = vcName as AnyObject
        newViewWindow["viewWindowID"] = viewWindowID as AnyObject
        newViewWindow["viewWindowEvent"] = "segued away" as AnyObject
        newViewWindow["viewWindowTimestamp"] = Date() as AnyObject
        newViewWindow.saveInBackground(block: (
            {(success: Bool, error: Error?) -> Void in
                if (!success) {
                    print("Error in saving new location to Parse: \(String(describing: error)). Attempting eventually.")
                    newViewWindow.saveEventually()
                }
        })
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //authorize location tracking
        locationMgr.requestAlwaysAuthorization()
        locationMgr.requestWhenInUseAuthorization()
        
        //authorize & initialize recording session
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission({ (allowed) in
                if allowed {
                    print("recording permission granted")
                } else {
                    print("ERROR: permission denied for audio")
                }
            })
        }
            
        catch {
            print("ERROR: error initializing audio")
        }

        if PFUser.current() == nil {
            self.performSegue(withIdentifier: "showLogin", sender: nil)
        }
        
        else {
            user = PFUser.current()!
            getProfileInfo()
            
            let font = UIFont.systemFont(ofSize: 20)
            roleButton.setTitleTextAttributes([NSFontAttributeName: font],
                                              for: UIControlState())
            roleButton.isSelected = false
        }
    }
    
    
    func getProfileInfo() {
        
        var role: String
        
        
        if user?.value(forKey: "role") == nil {
            //don't retrieve role
            nextButton.isEnabled = false
            roleButton.selectedSegmentIndex = UISegmentedControlNoSegment
        }
        else {
            nextButton.isEnabled = true
            role = (user?.value(forKey: "role"))! as! String
            if role == "runner" {
                roleButton.selectedSegmentIndex = 0
            }
            else if role == "spectator" {
                roleButton.selectedSegmentIndex = 1
            }
        }
    }
    
    @IBAction func selectRole(_ sender:UISegmentedControl) {
        switch roleButton.selectedSegmentIndex {
        case 0:
            user?["role"] = "runner"
            user?.saveInBackground()
            
        case 1:
            user?["role"] = "cheerer"
            user?.saveInBackground()
            
        default:
            break
        }
        nextButton.isEnabled = true
    }
    
    @IBAction func saveRole(_ sender: UIBarButtonItem) {
        switch roleButton.selectedSegmentIndex {
        case 0:
            self.performSegue(withIdentifier: "run", sender: nil)
        case 1:
            self.performSegue(withIdentifier: "cheer", sender: nil)
        default:
            break
        }
        
    }
}
