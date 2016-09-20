//
//  SignUpViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/11/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import Parse

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    var setupDate: NSDate = NSDate()
    var setupTimer: NSTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set timer to notify users to set up app on day of race
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        setupDate = dateFormatter.dateFromString(setupDateString)! //hardcoded dates for race day notifications
        setupTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(SignUpViewController.sendLocalNotification_setup), userInfo: nil, repeats: false)
        
        
        //set up rules for keyboard
        usernameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //set up scrollview behavior
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
        if isWiFiConnected()==false {
            turnOnWiFiAlert()
        }
        
        //if already logged in, segue to next VC
        if PFUser.currentUser() != nil {
            self.performSegueWithIdentifier("intro", sender: nil)
        }
    }
    
    
    //Check fields, Log In, and segue to next VC
    @IBAction func logIn(sender: UIButton) {
        PFUser.logInWithUsernameInBackground(usernameField.text, password:passwordField.text) {
            (user: PFUser?, error: NSError?) -> Void in
            if user != nil {
                // Successful login
                self.performSegueWithIdentifier("intro", sender: nil)
                
            } else {
                // failed login, error displayed to user
                let errorString = error!.userInfo["error"] as? String
                let alertController = UIAlertController(title: "Log In Error", message:
                    errorString, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    //Check fields, Sign Up, and segue to next VC
    @IBAction func signUp(sender: UIButton) {
        let user = PFUser()
        user.username = usernameField.text
        user.password = passwordField.text
        user.email = emailField.text
        
        user.signUpInBackgroundWithBlock {
            (succeeded: Bool, error: NSError?) -> Void in
            if let error = error {
                //failed signup, error displayed to user
                let errorString = error.userInfo["error"] as? String
                let alertController = UIAlertController(title: "Sign Up Error", message:
                    errorString, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
                
            } else {
                //Successful signup
                self.performSegueWithIdentifier("intro", sender: nil)
            }
        }
    }
    
    //keyboard behavior
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(notification:NSNotification){
        
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        keyboardFrame = view.convertRect(keyboardFrame, fromView: nil)
        
        var contentInset:UIEdgeInsets = scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(notification:NSNotification){
        
        let contentInset:UIEdgeInsets = UIEdgeInsetsZero
        scrollView.contentInset = contentInset
    }
    
    //Prompt user to turn on WiFi
    func turnOnWiFiAlert() {
        let alertTitle = "Location Accuracy"
        let alertController = UIAlertController(title: alertTitle, message: "Turn on Wi-Fi to improve location accuracy", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: openSettings))
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func openSettings(alert: UIAlertAction!) {
        UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=WIFI")!)
    }
    
    func isWiFiConnected() -> Bool {
        
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return false
        }
        
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                print("Reachable via WiFi")
                return true
            } else {
                print("Reachable via Cellular")
                return false
            }
        } else {
            print("Network not reachable")
            return false
        }
    }
    
    func sendLocalNotification_setup() {
        let localNotification = UILocalNotification()
        localNotification.alertBody = "Set up your profile before the race!"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.fireDate = setupDate
        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
}
