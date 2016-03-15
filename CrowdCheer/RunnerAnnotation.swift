//
//  RunnerAnnotation.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/10/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import UIKit
import MapKit

enum RunnerType: Int {
    case RunnerDefault = 0
    case MyRunner
}

class TrackRunnerAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var type: RunnerType
    var image: UIImage
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, type: RunnerType, image: UIImage) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.image = image
    }
}


class PickRunnerAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var type: RunnerType
    var runnerObjID: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, type: RunnerType, runnerObjID: String) {
        self.coordinate = coordinate
        self.title = title
        self.type = type
        self.runnerObjID = runnerObjID
    }
}