//
//  Users.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation

public protocol User {
    var username: String {get}
    var profilePic: String {get}
    var role: String {get}
}

struct runner: User {
    let username: String
    let profilePic: String
    let role: String
    let beacon: String
    let bibNumber: Int
    let racePic: String
    let targetTime: NSTimeInterval
    let targetPace: NSTimeInterval
}

struct cheerer: User {
    let username: String
    let profilePic: String
    let role: String
    let targetRunner: String
    
 // would instantiate without target runner - right now it is required
 /*   init(firstName: String,
        let profilePic: String,
        let role: String) {
        self.username = username
        self.profilePic = profilePic
        self.role = role
    }
*/
}