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
    var setupDate: Date = Date()
    var setupTimer: Timer = Timer()
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "SignupVC"
    
    override func viewDidAppear(_ animated: Bool) {
        
        viewWindowID = String(arc4random_uniform(10000000))
        
        let newViewWindowEvent = PFObject(className: "ViewWindows")
        if PFUser.current() != nil {
            newViewWindowEvent["userID"] = PFUser.current()!.objectId as AnyObject
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        let newViewWindow = PFObject(className: "ViewWindows")
        if PFUser.current() != nil {
            newViewWindow["userID"] = PFUser.current()!.objectId as AnyObject
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
        
        usernameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        //Flow 1 - Notify users 1hr before race to set up app (if they've opened app)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        setupDate = dateFormatter.date(from: setupDateString)! //hardcoded dates for race day notifications
        setupTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(SignUpViewController.sendLocalNotification_setup), userInfo: nil, repeats: false)
        
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //set up scrollview behavior
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Flow 2 - Check WiFi, alert if not on
        if isWiFiConnected()==false {
            turnOnWiFiAlert()
        }
        
        //Flow 3 - Segue if logged in already
        if PFUser.current() != nil {
            self.performSegue(withIdentifier: "intro", sender: nil)
        }
    }

    
    //Interaction 1 - Check fields, Log In, and segue to next VC
    @IBAction func logIn(_ sender: UIButton) {
        PFUser.logInWithUsername(inBackground: usernameField.text!, password:passwordField.text!) {
            (user: PFUser?, error: Error?) -> Void in
            if user != nil {
                // Successful login
                self.performSegue(withIdentifier: "intro", sender: nil)
                
            } else {
                // failed login, error displayed to user
                let errorString = (error! as NSError).userInfo["error"] as? String
                let alertController = UIAlertController(title: "Log In Error", message:
                    errorString, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.default,handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    //Interaction 2 - Check fields, Sign Up, and segue to next VC
    @IBAction func signUp(_ sender: UIButton) {
        let user = PFUser()
        user.username = usernameField.text
        user.password = passwordField.text
        user.email = emailField.text
        
        if ((usernameField.text?.isEmpty)! || (passwordField.text?.isEmpty)! || (emailField.text?.isEmpty)!) {
            let alertController = UIAlertController(title: "Sign Up Error", message:
                "Please complete all fields to sign up.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)

        }
        else {
            user.signUpInBackground {
                (succeeded: Bool, error: Error?) -> Void in
                if let error = error {
                    //failed signup, error displayed to user
                    let errorString = (error as NSError).userInfo["error"] as? String
                    let alertController = UIAlertController(title: "Sign Up Error", message:
                        errorString, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.default,handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                    
                    
                } else {
                    //Successful signup
                    self.performSegue(withIdentifier: "intro", sender: nil)
                }
            }
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
    
    //Prompt user to turn on WiFi
    func turnOnWiFiAlert() {
        let alertTitle = "Location Accuracy"
        let alertController = UIAlertController(title: alertTitle, message: "Turn on Wi-Fi to improve location accuracy", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.default, handler: openSettings))
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func openSettings(_ alert: UIAlertAction!) {
        UIApplication.shared.openURL(URL(string:"App-Prefs:root=WIFI")!)
    }
    
    func isWiFiConnected() -> Bool {
        
        let reachability = Reachability()!
        
        if reachability.isReachable {
            if reachability.isReachableViaWiFi {
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
        if #available(iOS 8.2, *) {
            localNotification.alertTitle = "Check CrowdCheer setup before race"
            localNotification.alertBody = "Runners: check if you're tracking your run before you start \nSpectators: make sure you get bib numbers from runners to track them"
        } else {
            localNotification.alertBody = "Make sure CrowdCheer is set up to track the race before it starts!"
        }

        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.timeZone = TimeZone.current
        localNotification.fireDate = setupDate
        localNotification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
}
