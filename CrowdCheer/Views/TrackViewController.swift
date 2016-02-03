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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //update the runner profile info
        //every second, update the map with the runner's location
        
        self.runnerTrackerTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "trackRunner", userInfo: nil, repeats: true)
    }
    
    func trackRunner() {
        
    }
    
    func getRunnerProfile() {
        
    }

}