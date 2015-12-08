//
//  Run.swift
//  CrowdCheer
//
//  Created by Christina Kim on 12/8/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class Run: NSManagedObject {
    
    @NSManaged var distance: NSNumber
    @NSManaged var startTimestamp: NSDate
    @NSManaged var endTimestamp: NSDate
    @NSManaged var locations: Array<CLLocation>
    
    var duration: NSTimeInterval {
        get {
            return endTimestamp.timeIntervalSinceDate(startTimestamp)
        }
    }
    
    func addDistance(distance: Double) {
        self.distance = NSNumber(double: (self.distance.doubleValue + distance))
    }
    
    func addNewLocation(location: CLLocation) {
        locations.append(location)
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        locations = [CLLocation]()
        startTimestamp = NSDate()
        distance = 0.0
    }
    
}