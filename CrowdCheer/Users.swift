//
//  Users.swift
//  CrowdCheer
//
//  Created by Leesha Maliakal on 11/17/15.
//  Copyright © 2015 Delta Lab. All rights reserved.
//

import Foundation
import Parse


//the USER protocol is to set and get any user information
protocol User: Any {
    var user: PFUser {get}
    
    func getsUser(objectID: String) -> PFUser
    func setsUser(user: PFUser)
}

class Runner: NSObject, User {
    
    var user: PFUser
    
    override init(){
        user = PFUser.currentUser()!
    }

    
    func getsUser(objectID: String) -> PFUser {
        
        user = PFQuery.getUserObjectWithId(objectID)
        return user
    }
    
    func setsUser(runner: PFUser) {
        
        runner.saveInBackgroundWithBlock { (_success:Bool, _error:NSError?) -> Void in
            if _error == nil
            {
                print("user saved")
            }
        }
        
    }
}
