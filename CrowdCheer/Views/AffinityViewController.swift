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
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "AffinityVC"
    
    //TODO: add view event logging
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
