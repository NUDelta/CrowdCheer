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
        
        let locationMgr = CLLocationManager()
        let locations: [CLLocation] = []
        initLocationManager(locationMgr)
       // var mapView: MKMapView
        
        
        
       /* func initMapView() {
            mapView.delegate = self
            mapView.mapType = MKMapType.Satellite
            mapView.showsUserLocation = true
        } */
        
        
        let runner = RunnerLocation()
        runner.trackUserLocation(locationMgr, didUpdateLocations: locations)
        runner.saveUserLocation(locationMgr, didUpdateLocations: locations)
        
        let testObject = PFObject(className: "TestObject")
        testObject["foo"] = "bar"
        testObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            print("Object has been saved.")
        }
        
        
    }
    
    func initLocationManager(locationMgr :CLLocationManager) {
        
        locationMgr.requestAlwaysAuthorization()
        locationMgr.requestWhenInUseAuthorization()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        locationMgr.startUpdatingLocation()
    }
}