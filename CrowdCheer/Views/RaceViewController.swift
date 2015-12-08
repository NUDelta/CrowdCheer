//
//  RaceViewController.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class RaceViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var locationMgr: CLLocationManager
        var mapView: MKMapView
        
        func initLocationManager() {
            locationMgr = CLLocationManager()
            locationMgr.delegate = self
            locationMgr.desiredAccuracy = kCLLocationAccuracyBest
            locationMgr.requestAlwaysAuthorization()
            locationMgr.startUpdatingLocation()
            
        }
        
        func initMapView() {
            mapView.delegate = self
            mapView.mapType = MKMapType.Satellite
            mapView.showsUserLocation = true
        }
    }
}