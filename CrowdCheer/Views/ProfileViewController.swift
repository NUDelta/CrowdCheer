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

class ProfileViewController: UIViewController, CLLocationManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let locationMgr: CLLocationManager = CLLocationManager()
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
        
        user = PFUser.currentUser()
        nameField.addTarget(self, action: #selector(ProfileViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
//        self.navigationItem.setHidesBackButton(true, animated:true);
        self.logOut.hidden = true
        
        //set up rules for keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        displayPhotoAlert()
        getProfileInfo()
        
        if (user.valueForKey("name")==nil) || (user.valueForKey("profilePic")==nil)  {
            self.saveButton.enabled = false
        }
        else {
            self.saveButton.enabled = true
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
        if (textField == self.nameField){
            user["name"] = self.nameField.text
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
            self.nameField.text = name
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
    
    func displayPhotoAlert() {
        let alertController = UIAlertController(title: "Race Day Photo", message: "Take a new pic in your race day outfit so CrowdCheer users can easily find you on the race course.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
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
        
        let imageData = UIImageJPEGRepresentation(self.image!, 0.50)
        let imageFile = PFFile.fileWithName("image.jpeg", data: imageData!)
        user["profilePic"] = imageFile
        user.saveInBackground()
    }
    
    @IBAction func logOut(sender: UIButton) {
        PFUser.logOut()
        let sb = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let loginView = sb.instantiateViewControllerWithIdentifier("signUpViewController")
        self.presentViewController(loginView, animated: true, completion: nil)
    }
}

