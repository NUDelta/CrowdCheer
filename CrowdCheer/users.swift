//
//  users.swift
//  CrowdCheer
//
//  Created by Christina Kim on 10/28/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation

public protocol tracking {
    func startLocationUpdates()
    func trackUser()
    func locationManager()
}

struct runner: tracking {
    func startLocationUpdates(){
    }
    func trackUser() {
    }
    func locationManager(){
    }
}

struct cheerer {
    func startLocationUpdates(){
    }
    func trackUser() {
    }
    func locationManager(){
    }
}
