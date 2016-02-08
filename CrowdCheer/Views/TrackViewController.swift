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
    
    let locationMgr: CLLocationManager = CLLocationManager()
    var runnerTrackerTimer: NSTimer = NSTimer()
    var runner: PFUser = PFUser()
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var contextPrimer = ContextPrimer()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize map
        //update the runner profile info
        //every second, update the distance label and map with the runner's location

        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        getRunnerProfile()
        self.runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "trackRunner", userInfo: nil, repeats: true)
        self.contextPrimer = ContextPrimer()
        
        
    }
    
    func trackRunner() {
        //get latest loc and update map and distance label
        
        print("Tracking runner")
        let trackedRunnerID: String = self.runner.objectId
        let annotation = MKPointAnnotation()
        
        self.contextPrimer.getRunnerLocation(trackedRunnerID) { (runnerLoc) -> Void in

            self.runnerLastLoc = runnerLoc
            print("runnerLastLoc inside timer", self.runnerLastLoc)
        }
        
        print("runnerLastLoc: ",self.runnerLastLoc)
        self.runnerPath.append(self.runnerLastLoc)
        annotation.coordinate = self.runnerLastLoc
        self.mapView.addAnnotation(annotation)
        //            let geodesic = MKGeodesicPolyline(coordinates: &self.runnerPath[0] , count: self.runnerPath.count)
        //            self.mapView.addOverlay(geodesic)
        
        let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
        let distance = (self.locationMgr.location?.distanceFromLocation(runnerCLLoc))!
        self.distanceLabel.text = String(format: " %.02f", distance) + "m away"
    }
    
    func getRunnerProfile() {
        
        self.contextPrimer.getRunner(){ (runnerObject) -> Void in
            //update runner name, bib #, picture
            
            self.runner = PFQuery.getUserObjectWithId(runnerObject.objectId!)
            let runnerName = (self.runner.valueForKey("name"))!
            let runnerBib = (self.runner.valueForKey("bibNumber"))!
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