//
//  RaceViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
/* Copyright © 2015 Delta Lab. All rights reserved.
locations = [CLLocation(latitude: 38.5, longitude: -120.2),
    CLLocation(latitude: 40.7000, longitude: -120.95000),
    CLLocation(latitude: 43.25200, longitude: -126.453000)]

*/

import UIKit
import Foundation
import CoreLocation
import MapKit
import Parse

class RaceViewController: UIViewController, /*MKMapViewDelegate*/ CLLocationManagerDelegate {
    
    
    let isTracking: Bool = true
    let isRacer: Bool = false
    let isCheerer: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
         print("Object is doing a thing.")
        var locationMgr: CLLocationManager
       // var mapView: MKMapView
        
        func initLocationManager() {
            locationMgr = CLLocationManager()
            locationMgr.delegate = self
            locationMgr.desiredAccuracy = kCLLocationAccuracyBest
            locationMgr.requestAlwaysAuthorization()
            locationMgr.startUpdatingLocation()
            
            
            
        }
        
        //this is saving to parse
        func saveLocation(){
            var loc =  locationMgr.location!.coordinate
            var actualLocation = PFGeoPoint(latitude:loc.latitude,longitude:loc.longitude)
            print("did we get in here")
            let object = PFObject(className:"TestLocations")
            object["Location"] = actualLocation
            object.saveInBackgroundWithBlock { (_success:Bool, _error:NSError?) -> Void in
                if _error == nil
                {
                    print("location saved")
                }
            }
        }
        
       /* func initMapView() {
            mapView.delegate = self
            mapView.mapType = MKMapType.Satellite
            mapView.showsUserLocation = true
        } */
        
        let testObject = PFObject(className: "TestObject")
        testObject["foo"] = "bar"
        testObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            print("Object has been saved.")
        }
        
        
    }
}