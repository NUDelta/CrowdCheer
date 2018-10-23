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
    
    var runner: PFUser = PFUser.current()!
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var targetPace: UITextField!
    @IBOutlet weak var raceTimeGoal: UITextField!
    @IBOutlet weak var bibNo: UITextField!
    @IBOutlet weak var cheer: UITextField!
    @IBOutlet weak var outfit: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var currUser: PFUser = PFUser.current()!
    var runnerMonitor: RunnerMonitor = RunnerMonitor()
    
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "PrerunVC"
    
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
        
        //set up view
        saveButton.isEnabled = true
        
        targetPace.addTarget(self, action: #selector(PrerunViewController.textFieldShouldEndEditing(_:)), for: UIControlEvents.editingDidEnd)
        raceTimeGoal.addTarget(self, action: #selector(PrerunViewController.textFieldShouldEndEditing(_:)), for: UIControlEvents.editingDidEnd)
        bibNo.addTarget(self, action: #selector(PrerunViewController.textFieldShouldEndEditing(_:)), for: UIControlEvents.editingDidEnd)
        cheer.addTarget(self, action: #selector(PrerunViewController.textFieldShouldEndEditing(_:)), for: UIControlEvents.editingDidEnd)
        outfit.addTarget(self, action: #selector(PrerunViewController.textFieldShouldEndEditing(_:)), for: UIControlEvents.editingDidEnd)
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PrerunViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //set up scrollview behavior
        NotificationCenter.default.addObserver(self, selector: #selector(PrerunViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PrerunViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        runnerMonitor = RunnerMonitor()
        getPrerunInfo()
    }
    
    func getPrerunInfo() {
        
        var pace: String
        var time: String
        var bibNum: String
        var outfitDetail: String
        var cheerDetail: String
        
        //get pace
        if runner.value(forKey: "targetPace") == nil {
            //don't retrieve pace
        }
        else {
            pace = (runner.value(forKey: "targetPace"))! as! String
            targetPace.text = pace
        }
        
        //get time
        if runner.value(forKey: "raceTimeGoal") == nil {
            //don't retrieve time
        }
        else {
            time = (runner.value(forKey: "raceTimeGoal"))! as! String
            raceTimeGoal.text = time
        }
        
        //get bibNo
        if runner.value(forKey: "bibNumber") == nil {
            //don't retrieve bib no
        }
        else {
            bibNum = (runner.value(forKey: "bibNumber"))! as! String
            bibNo.text = bibNum
        }
        
        //get outfit
        if runner.value(forKey: "outfit") == nil {
            //don't retrieve outfit
        }
        else {
            outfitDetail = (runner.value(forKey: "outfit"))! as! String
            outfit.text = outfitDetail
        }
        
        //get cheer
        if runner.value(forKey: "cheer") == nil {
            //don't retrieve outfit
        }
        else {
            cheerDetail = (runner.value(forKey: "cheer"))! as! String
            cheer.text = cheerDetail
        }
    }
    
    //keyboard behavior
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) {
        
        //save profile info to Parse
        if (textField == targetPace){
            currUser["targetPace"] = targetPace.text
            currUser.saveInBackground()
        }
            
        else if (textField == raceTimeGoal){
            currUser["raceTimeGoal"] = raceTimeGoal.text
            currUser.saveInBackground()
        }
            
        else if (textField == bibNo){
            currUser["bibNumber"] = bibNo.text
            currUser.saveInBackground()
        }
            
        else if (textField == outfit){
            currUser["outfit"] = outfit.text
            currUser.saveInBackground()
        }
        
        else if (textField == cheer){
            currUser["cheer"] = cheer.text
            currUser.saveInBackground()
        }
    }
    
    @IBAction func saveRaceInfo(_ sender: UIButton) {
        if (currUser.value(forKey: "targetPace")==nil ||
            currUser.value(forKey: "raceTimeGoal")==nil ||
            currUser.value(forKey: "bibNumber")==nil ||
            currUser.value(forKey: "outfit")==nil ||
            currUser.value(forKey: "cheer")==nil) {
            
            profileInfoMissingAlert()
        }
        else {
            performSegue(withIdentifier: "saveRaceInfo", sender: nil)
        }
    }
    
    
    func profileInfoMissingAlert() {
        let alertTitle = "Missing Info"
        let alertController = UIAlertController(title: alertTitle, message: "You must enter all race info to continue.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func keyboardWillShow(_ notification:Notification){
        
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(_ notification:Notification){
        
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }

}
