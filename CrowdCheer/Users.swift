//
//  Users.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation

public protocol User {
    var name: String
    var profilePic
    var role: String
}

struct runner: User {
    var name: String
    var profilePic
    var role: String
    var beacon: String
    var bibNumber: Int
    var racePic
    var targetTime
    var targetPace
}

struct cheerer: User {
    var name: String
    var profilePic
    var role: String
    var targetRunner
}