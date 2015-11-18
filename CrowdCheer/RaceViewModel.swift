//
//  RaceViewModel.swift
//  CrowdCheer
//
//  Created by Christina Kim on 10/30/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UIKit

struct RaceViewModel: Tracking {
    
    var locations: [CLLocation]
    var distance: Double
    var pace: NSTimeInterval
    var duration: NSTimeInterval
    
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
        mapView.showUserLocation = true
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        mapLabel.text = "\(locations[0])"
        myLocations.append(locations[0])
        
        let spanX = 0.007
        let spanY = 0.007
        var newRegion = MKCoordinateRegion(center: map.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(newRegion, animated: true)
        
        if (myLocations.count > 1){
            var sourceIndex = myLocations.count - 1
            var destinationIndex = myLocations.count - 2
            
            let c1 = myLocations[sourceIndex].coordinate
            let c2 = myLocations[destinationIndex].coordinate
            var a = [c1, c2]
            var polyline = MKPolyline(coordinates: &a, count: a.count)
            map.addOverlay(polyline)
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 4
            return polylineRenderer
        }
        return nil
    }
    
    
}



