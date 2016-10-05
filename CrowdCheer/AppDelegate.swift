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
let setupDateString = "2016-10-04T20:00:00-05:00" // 1hr before race
let prestartDateString = "2016-10-04T20:55:00-05:00" // 5 min before race
let startDateString = "2016-10-04T21:00:00-05:00" // race start time
var nearbyTargetRunnersTimer: NSTimer = NSTimer()


@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let userDefault = NSUserDefaults.init()
    
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
      
        // Initialize Parse
        Parse.setApplicationId("QXRTROGsVaRn4a3kw4gaFnHGNOsZxXoZ8ULxwZmf", clientKey: "gINJkaTkxsafobZ0QFZ0HAT32tjdx06aoF6b2VNQ")
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))
        
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("app entered background")
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        application.applicationIconBadgeNumber = 0
        
        if (notification.userInfo != nil) {
            
            if (notification.userInfo?["spectator"]) != nil {
                let newNotification = PFObject(className: "SpectatorNotifications")
                newNotification["spectator"] = notification.userInfo!["spectator"]
                newNotification["source"] = notification.userInfo!["source"]
                newNotification["receivedNotification"] = notification.userInfo!["receivedNotification"]
                newNotification["receivedNotificationTimestamp"] = notification.userInfo!["receivedNotificationTimestamp"]
                newNotification["unreadNotificationCount"] = notification.userInfo!["unreadNotificationCount"]
                newNotification.saveInBackground()
            }
        }
    }
}

