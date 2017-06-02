//
//  AppDelegate.swift
//  test
//
//  Created by Leesha Maliakal on 2/10/16.
//  Copyright © 2016 Delta Lab. All rights reserved.
//

import UIKit
import Parse

let dictKey = "key"
let setupDateString = "2017-06-04T06:00:00-05:00" // 1 hr before race
var nearbyTargetRunnersTimer: Timer = Timer()


@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let userDefault = UserDefaults.init()
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
      
        // Initialize Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = "QXRTROGsVaRn4a3kw4gaFnHGNOsZxXoZ8ULxwZmf"
            $0.clientKey = "gINJkaTkxsafobZ0QFZ0HAT32tjdx06aoF6b2VNQ"
            $0.server = "https://crowdcheerdb.herokuapp.com/parse"
        }
        Parse.initialize(with: configuration)
        
        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("app entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        
        application.applicationIconBadgeNumber = 0
        
        if (notification.userInfo != nil) {
            
            if (notification.userInfo?["spectator"]) != nil {
                let newNotification = PFObject(className: "SpectatorNotifications")
                newNotification["spectator"] = notification.userInfo!["spectator"]
                newNotification["source"] = notification.userInfo!["source"]
                newNotification["notificationID"] = notification.userInfo!["notificationID"]
                newNotification["receivedNotification"] = notification.userInfo!["receivedNotification"]
                newNotification["receivedNotificationTimestamp"] = notification.userInfo!["receivedNotificationTimestamp"]
                newNotification["unreadNotificationCount"] = notification.userInfo!["unreadNotificationCount"]
                newNotification.saveInBackground()
            }
        }
    }
}

