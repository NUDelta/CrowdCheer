//
//  TrackViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/1/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Parse

class TrackViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bibLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var runnerTrackerTimer: NSTimer = NSTimer()
    var runner: PFUser = PFUser()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //update the runner profile info
        //every second, update the map with the runner's location
        
        getRunnerProfile()
        self.runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "trackRunner", userInfo: nil, repeats: true)
        
    }
    
    func trackRunner() {
        print("Tracking runner")
    }
    
    func getRunnerProfile() {
        
        let contextPrimer = ContextPrimer()
        contextPrimer.getRunner(){ (runnerObject) -> Void in
            
            self.runner = PFQuery.getUserObjectWithId(runnerObject.objectId!)
            let runnerName = (self.runner.valueForKey("name"))!
            let runnerBib = (self.runner.valueForKey("bibNumber"))!
//            let runnerPic = (self.runner.valueForKey("profilePic"))
            
            let userImageFile = self.runner["profilePic"] as? PFFile
            userImageFile!.getDataInBackgroundWithBlock {
                (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        let image = UIImage(data:imageData)
                        self.profilePic.image = image
                    }
                }
            }
            
            
            print("name: \(runnerName) bib: \(runnerBib)")
            
            self.nameLabel.text = runnerName as? String
            self.bibLabel.text = runnerBib as? String
            
        }
    }
}