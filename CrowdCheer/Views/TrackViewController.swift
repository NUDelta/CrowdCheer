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
    var runnerAnnotationTimer: NSTimer = NSTimer()
    var runner: PFUser = PFUser()
    var runnerLastLoc = CLLocationCoordinate2D()
    var runnerPath: Array<CLLocationCoordinate2D> = []
    var contextPrimer = ContextPrimer()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize map
        //update the runner profile info
        //every second, update the distance label and map with the runner's location

        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true);
        getRunnerProfile()
        self.runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "trackRunner", userInfo: nil, repeats: true)
//        self.runnerAnnotationTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "updateRunnerPin", userInfo: nil, repeats: true)
        self.contextPrimer = ContextPrimer()
        
        
    }
    
    func trackRunner() {
        //get latest loc and update map and distance label
        
        print("Tracking runner")
        let trackedRunnerID: String = self.runner.objectId
//        let annotation = MKPointAnnotation()
        
        self.contextPrimer.getRunnerLocation(trackedRunnerID) { (runnerLoc) -> Void in

            self.runnerLastLoc = runnerLoc
        }
        
        if (self.runnerLastLoc.latitude == 0.0 && self.runnerLastLoc.longitude == 0.0) {
            print("skipping coordinate")
        }
        else {
            self.runnerPath.append(self.runnerLastLoc)
            print("runnerPath: ", self.runnerPath)
        }
    
//        annotation.coordinate = self.runnerLastLoc
//        self.mapView.addAnnotation(annotation)
        let runnerCLLoc = CLLocation(latitude: self.runnerLastLoc.latitude, longitude: self.runnerLastLoc.longitude)
        let distance = (self.locationMgr.location?.distanceFromLocation(runnerCLLoc))!
        self.distanceLabel.text = String(format: " %.02f", distance) + "m away"
        drawPath()
        updateRunnerPin()
    }
    
    func getRunnerProfile() {
        
        self.contextPrimer.getRunner(){ (runnerObjectID) -> Void in
            //update runner name, bib #, picture
            print("runnerObjID: ", runnerObjectID)
            self.runner = PFQuery.getUserObjectWithId(runnerObjectID)
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
            
            self.nameLabel.text = runnerName as? String
            self.bibLabel.text = runnerBib as? String
            
        }
    }
    
    func drawPath() {
        
        if(self.runnerPath.count > 1) {
            let polyline = MKPolyline(coordinates: &self.runnerPath[0] , count: self.runnerPath.count)
            self.mapView.addOverlay(polyline)
        }
        
    }
    
    func updateRunnerPin() {
        
        let coordinate = self.runnerLastLoc
        let title = self.nameLabel.text
        let type = RunnerType(rawValue: 0) //type would be 1 if it's my runner
        let subtitle = ("Bib #:" + self.bibLabel.text!)
        let annotation = RunnerAnnotation(coordinate: coordinate, title: title!, subtitle: subtitle, type: type!)

        let annotationsToRemove = self.mapView.annotations.filter { $0 !== self.mapView.userLocation }
        self.mapView.removeAnnotations(annotationsToRemove)
        self.mapView.addAnnotation(annotation)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
//        if overlay.isKindOfClass(MKPolyline) {

            // render the path
            assert(overlay.isKindOfClass(MKPolyline))
            let polyLine = overlay
            let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
            polyLineRenderer.strokeColor = UIColor.blueColor()
            polyLineRenderer.lineWidth = 3.0
            
            return polyLineRenderer
//        }
//        
//        return MKPolylineRenderer()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKUserLocation) {
            return nil
        }
        else {
            let annotationView = RunnerAnnotationView(annotation: annotation, reuseIdentifier: "Runner")
            annotationView.canShowCallout = true
            return annotationView
        }
    }
}