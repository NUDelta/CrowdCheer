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
    
    
    //TODO: add view event logging
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up view
        saveButton.isEnabled = false
        
        targetPace.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        raceTimeGoal.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        bibNo.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        cheer.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        outfit.addTarget(self, action: #selector(PrerunViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PrerunViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //set up scrollview behavior
        NotificationCenter.default.addObserver(self, selector: #selector(PrerunViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PrerunViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if (targetPace.text != "" || raceTimeGoal.text != "" || bibNo.text != "" || outfit.text != "" || cheer.text != "") {
            saveButton.isEnabled = true
        }
        
        runnerMonitor = RunnerMonitor()
        getPrerunInfo()
        
        if (currUser.value(forKey: "targetPace")==nil ||
            currUser.value(forKey: "raceTimeGoal")==nil ||
            currUser.value(forKey: "bibNumber")==nil ||
            currUser.value(forKey: "cheer")==nil ||
            currUser.value(forKey: "outfit")==nil){
            saveButton.isEnabled = false
        }
        else {
            saveButton.isEnabled = true
        }
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
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        //save profile info to Parse
        if (textField == targetPace){
            currUser["targetPace"] = targetPace.text
        }
            
        else if (textField == raceTimeGoal){
            currUser["raceTimeGoal"] = raceTimeGoal.text
        }
            
        else if (textField == bibNo){
            currUser["bibNumber"] = bibNo.text
        }
            
        else if (textField == outfit){
            currUser["outfit"] = outfit.text
        }
        
        else if (textField == cheer){
            currUser["cheer"] = cheer.text
        }
        
        currUser.saveInBackground()
        
        if (currUser.value(forKey: "targetPace")==nil ||
            currUser.value(forKey: "raceTimeGoal")==nil ||
            currUser.value(forKey: "bibNumber")==nil ||
            currUser.value(forKey: "outfit")==nil ||
            currUser.value(forKey: "cheer")==nil) {
            saveButton.isEnabled = false
        }
        else {
            saveButton.isEnabled = true
        }
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
