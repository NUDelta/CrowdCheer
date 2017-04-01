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
    
    func getsUser(_ objectID: String) -> PFUser
    func setsUser(_ user: PFUser)
}

class Runner: NSObject, User {
    
    var user: PFUser
    
    override init(){
        user = PFUser.current()!
    }

    
    func getsUser(_ objectID: String) -> PFUser {
        
        do {
            user = try PFQuery.getUserObject(withId: objectID)
        }
        catch {
            print("ERROR: unable to get runner")
        }
        return user
    }
    
    func setsUser(_ runner: PFUser) {
        
        runner.saveInBackground { (_success:Bool, _error:NSError?) -> Void in
            if _error == nil
            {
                print("user saved")
            }
        }
        
    }
}
