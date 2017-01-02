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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize user, profile info
        user = PFUser.currentUser()!
        getProfileInfo()
        
        //Prompt user to take new photo & add listener for changes in name field
        nameField.addTarget(self, action: #selector(ProfileViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Ensure profile pic and name are saved before enabling segue
        if (user.valueForKey("name")==nil) || (user.valueForKey("profilePic")==nil )  {
            saveButton.enabled = false
        }
        else {
            saveButton.enabled = true
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
    
    func textFieldDidChange(textField: UITextField) {
        //save profile info to Parse
        if (textField == nameField){
            user["name"] = nameField.text
        }
        
        user.saveInBackground()
    }
    
    func getProfileInfo() {
        
        var name: String
        var userImageFile: PFFile
        
        if user.valueForKey("name") == nil {
            //don't retrieve name
        }
        else {
            name = (user.valueForKey("name"))! as! String
            nameField.text = name
        }
        
        if user.valueForKey("profilePic") == nil {
            //don't retrieve profile picture
        }
        else {
            userImageFile = user["profilePic"] as! PFFile
            userImageFile.getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        let image = UIImage(data:imageData)
                        self.profilePicView.image = image
                    }
                }
                else {
                    print("could not download photo: \(error)")
                }
            }
        }
    }
    
    @IBAction func updatePicture(sender: UIButton) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .Camera
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject]) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        profilePicView.image = image
        
        let imageData = UIImageJPEGRepresentation(image!, 0.50)
        let imageFile = PFFile(name: "image.jpeg", data: imageData!)
        user["profilePic"] = imageFile
        user.saveInBackground()
        
        if user.valueForKey("profilePic") != nil {
            saveButton.enabled = true
        }
    }
    
    @IBAction func logOut(sender: UIButton) {
        PFUser.logOut()
        let sb = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let loginView = sb.instantiateViewControllerWithIdentifier("signUpViewController")
        self.presentViewController(loginView, animated: true, completion: nil)
    }
}

