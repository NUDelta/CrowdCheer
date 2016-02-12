////
////  Users.swift
////  CrowdCheer
////
////  Created by Leesha Maliakal on 11/17/15.
////  Copyright © 2015 Delta Lab. All rights reserved.
////
//
//import Foundation
//import Parse
//
//
////the USER protocol is to set and get any user information
//protocol User: Any {
//    var user: PFUser {get}
//    var username: String {get set}
//    var password: String {get set}
//    var email: String {get set}
//    var profilePic: UIImage {get set}
//    var name: String {get set}
//    var role: String {get set}
//    var bibNumber: String {get set}
//    var raceTimeGoal: String {get set}
//    var beacon: String {get set}
//    var targetPace: String {get set}
//    
//    func getUser() -> PFUser
//    func setUser(user: PFUser)
//}
//
//class Runner: NSObject, User {
//    
//    var user: PFUser
//    var username: String
//    var password: String
//    var email: String
//    var profilePic: UIImage
//    var name: String
//    var role: String
//    var bibNumber: String
//    var raceTimeGoal: String
//    var beacon: String
//    var targetPace: String
//    
//    override init(){
//        self.user = PFUser.currentUser()
//        self.username = ""
//        self.password = ""
//        self.email = ""
//        self.profilePic = UIImage()
//        self.name = ""
//        self.role = ""
//        self.bibNumber = ""
//        self.raceTimeGoal = "'"
//        self.beacon = ""
//        self.targetPace = ""
//    }
//
//    
//    func getUser() -> PFUser {
//        
//    }
//    
//    func setUser(runner: PFUser) {
//        
//    }
//}
//a