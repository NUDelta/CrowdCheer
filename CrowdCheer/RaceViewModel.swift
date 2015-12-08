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

struct RaceViewModel {
    
    var locations: [CLLocation]
    var distance: Double
    var pace: NSTimeInterval
    var duration: NSTimeInterval
    
    var locationMgr: CLLocationManager
    var mapView: MKMapView
    var mapLabel: UILabel
    
    func locationManager(manager:CLLocationManager, var didUpdateLocations locations:[CLLocation]) {
        mapLabel.text = "\(locations[0])"
        locations.append(locations[0])
        
        let spanX = 0.007
        let spanY = 0.007
        var newRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        mapView.setRegion(newRegion, animated: true)
        
        if (locations.count > 1){
            var sourceIndex = locations.count - 1
            var destinationIndex = locations.count - 2
            
            let c1 = locations[sourceIndex].coordinate
            let c2 = locations[destinationIndex].coordinate
            var a = [c1, c2]
            var polyline = MKPolyline(coordinates: &a, count: a.count)
            mapView.addOverlay(polyline)
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



