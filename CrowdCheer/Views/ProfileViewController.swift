//
//  ProfileViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/8/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Foundation
import MapKit
import Parse

class ProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var user: PFUser = PFUser()
    var imagePicker: UIImagePickerController!
    var image: UIImage?
    
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var profilePicView: UIImageView!
    @IBOutlet weak var updatePicture: UIButton!
    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    let appDel = UserDefaults()
    var viewWindowID: String = ""
    var vcName = "ProfileVC"
    
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
        
        //Initialize user, profile info
        user = PFUser.current()!
        getProfileInfo()
        
        //Prompt user to take new photo & add listener for changes in name field
        nameField.addTarget(self, action: #selector(ProfileViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Ensure profile pic and name are saved before enabling segue
        if (user.value(forKey: "name")==nil) || (user.value(forKey: "profilePic")==nil )  {
            saveButton.isEnabled = false
        }
        else {
            saveButton.isEnabled = true
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
        if (textField == nameField){
            user["name"] = nameField.text
        }
        
        user.saveInBackground()
    }
    
    func getProfileInfo() {
        
        var name: String
        var userImageFile: PFFile
        
        if user.value(forKey: "name") == nil {
            //don't retrieve name
        }
        else {
            name = (user.value(forKey: "name"))! as! String
            nameField.text = name
        }
        
        if user.value(forKey: "profilePic") == nil {
            //don't retrieve profile picture
        }
        else {
            userImageFile = user["profilePic"] as! PFFile
            userImageFile.getDataInBackground {
                (imageData: Data?, error: Error?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        let image = UIImage(data:imageData)
                        self.profilePicView.image = image
                    }
                }
                else {
                    print("could not download photo: \(String(describing: error))")
                }
            }
        }
    }
    
    @IBAction func updatePicture(_ sender: UIButton) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        profilePicView.image = image
        
        let imageData = UIImageJPEGRepresentation(image!, 0.50)
        let imageFile = PFFile(name: "image.jpeg", data: imageData!)
        user["profilePic"] = imageFile
        user.saveInBackground()
        
        if user.value(forKey: "profilePic") != nil {
            saveButton.isEnabled = true
        }
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        PFUser.logOut()
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let loginView = sb.instantiateViewController(withIdentifier: "signUpViewController")
        self.present(loginView, animated: true, completion: nil)
    }
}

