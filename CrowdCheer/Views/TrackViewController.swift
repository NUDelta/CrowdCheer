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
    var runnerPath: Array<CLLocationCoordinate2D> = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize map
        //update the runner profile info
        //every second, update the distance label and map with the runner's location

        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        getRunnerProfile()
        self.runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "trackRunner", userInfo: nil, repeats: true)
        
        
    }
    
    func trackRunner() {
        print("Tracking runner")
        let contextPrimer = ContextPrimer()
        var trackedRunner = PFUser()
        let annotation = MKPointAnnotation()
        
        contextPrimer.getRunner { (runnerObject) -> Void in
            trackedRunner = PFQuery.getUserObjectWithId(runnerObject.objectId!)
        }
        contextPrimer.getRunnerLocation(trackedRunner) { (runnerLoc) -> Void in
            //update map and distance label
            
            
            print("runnerLastLoc: ",runnerLoc)
            self.runnerPath.append(runnerLoc)
            annotation.coordinate = runnerLoc
            self.mapView.addAnnotation(annotation)
//            let geodesic = MKGeodesicPolyline(coordinates: &self.runnerPath[0] , count: self.runnerPath.count)
//            self.mapView.addOverlay(geodesic)
            
            let distance = (self.locationMgr.location?.distanceFromLocation(CLLocation(latitude: runnerLoc.latitude, longitude: runnerLoc.longitude)))!
            self.distanceLabel.text = String(format: " %.02f", distance) + "m away"
        }
    }
    
    func getRunnerProfile() {
        
        let contextPrimer = ContextPrimer()
        contextPrimer.getRunner(){ (runnerObject) -> Void in
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