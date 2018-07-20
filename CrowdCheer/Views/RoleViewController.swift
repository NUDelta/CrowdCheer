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
    var user: PFUser = PFUser.current()!
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "RoleVC"
    
    override func viewDidAppear(_ animated: Bool) {
        
        viewWindowID = String(arc4random_uniform(10000000))
        
        let newViewWindowEvent = PFObject(className: "ViewWindows")
        newViewWindowEvent["userID"] = PFUser.current()!.objectId as AnyObject
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        let newViewWindow = PFObject(className: "ViewWindows")
        newViewWindow["userID"] = PFUser.current()!.objectId as AnyObject
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

        
        
        user = PFUser.current()!
        getProfileInfo()
        
        let font = UIFont.systemFont(ofSize: 20)
        roleButton.setTitleTextAttributes([NSFontAttributeName: font],
                                          for: UIControlState())
        roleButton.isSelected = false
        
    }
    
    
    func getProfileInfo() {
        
        var role: String
        
        
        if user.value(forKey: "role") == nil {
            //don't retrieve role
        }
        else {
            role = (user.value(forKey: "role"))! as! String
            if role == "runner" {
                roleButton.selectedSegmentIndex = 0
            }
            else {
                roleButton.selectedSegmentIndex = 1
            }
        }
    }
    
    @IBAction func selectRole(_ sender:UISegmentedControl) {
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
