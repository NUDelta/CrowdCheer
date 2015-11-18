//
//  Users.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation

public protocol User {
    var name: String {get set}
    var profilePic: String {get set}
    var role: String {get set}
}

struct runner: User {
    var name: String
    var profilePic: String
    var role: String
    var beacon: String
    var bibNumber: Int
    var racePic: String
    var targetTime: NSTimeInterval
    var targetPace: NSTimeInterval
}

struct cheerer: User {
    var name: String
    var profilePic: String
    var role: String
    var targetRunner: String
}