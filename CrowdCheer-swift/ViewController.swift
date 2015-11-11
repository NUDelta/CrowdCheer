//
//  ViewController.swift
//  CrowdCheer-swift
//
//  Created by Christina Kim on 11/10/15.
//  Copyright © 2015 Christina Kim. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var mapLabel: UILabel!
    
    var manager:CLLocationManager!
    var myLocations: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup our Location Manager
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
        //Setup our Map View
        map.delegate = self
        map.mapType = MKMapType.Satellite
        map.showsUserLocation = true
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
    
    func startMonitoring(sender: AnyObject) {
        // setting loc
        var latitude:CLLocationDegrees = 37.039278
        var longitude: CLLocationDegrees = -122
        var center: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        var radius: CLLocationDistance = CLLocationDistance(1.0)
        var identifier: String = "vicmic"
        
        var geoRegion:CLCircularRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        
    }
}