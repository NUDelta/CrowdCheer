//
//  RunnerAnnotationView.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/10/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class TrackRunnerAnnotationView: MKAnnotationView {
    // Required for MKAnnotationView
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Called when drawing the RunnerAnnotationView
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let runnerAnnotation = self.annotation as! TrackRunnerAnnotation
        switch (runnerAnnotation.type) {
            case .MyRunner:
                image = UIImage(named: "myrunner.png")
            default:
                image = UIImage(named: "runner.png")
        }
    }
}

class PickRunnerAnnotationView: MKAnnotationView {
    // Required for MKAnnotationView
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Called when drawing the RunnerAnnotationView
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let runnerAnnotation = self.annotation as! PickRunnerAnnotation
        switch (runnerAnnotation.type) {
        case .MyRunner:
            image = UIImage(named: "myrunner.png")
        default:
            image = UIImage(named: "runner.png")
        }
    }
}