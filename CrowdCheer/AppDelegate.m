//
//  AppDelegate.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/8/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "HomeViewController.h"
#import "DefaultSettingsViewController.h"
#import "RoleViewController.h"
#import "CheererStartViewController.h"
#import "MotivatorViewController.h"
#import "RelationshipViewController.h"
#import "CommonalityViewController.h"
#import <Parse/Parse.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //Parse Setup
    //    [Parse enableLocalDatastore];
    
    // Initialize Parse.
    [Parse setApplicationId:@"QXRTROGsVaRn4a3kw4gaFnHGNOsZxXoZ8ULxwZmf"
                  clientKey:@"gINJkaTkxsafobZ0QFZ0HAT32tjdx06aoF6b2VNQ"];
    
    [[UIApplication sharedApplication]
     setMinimumBackgroundFetchInterval:
     UIApplicationBackgroundFetchIntervalMinimum];
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    // Override point for customization after application launch.
    // Handle launching from a notification
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    /**
     if (notification) {
     [self showAlarm:notification.alertBody];
     NSLog(@"AppDelegate didFinishLaunchingWithOptions");
     application.applicationIconBadgeNumber = 0;
     }
     */
    
    //This code here will listen for notifications sent from
    // MotivatorViewController.m checkForRunners
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showAlarm:)
                                                 name:@"DataUpdated"
                                               object:nil];
    
    [self.window makeKeyAndVisible];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Override point for customization after application launch.
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    CommonalityViewController *controller = (CommonalityViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.managedObjectContext;
    return YES;
    
}

- (void)showAlarm:(NSNotification *)notification {
    //displays notification
    // showAlarm gets called from notification that is registered in didFinishLaunchingWithOptions at the top of this class
    // this code was borrowed from http://www.appcoda.com/ios-programming-local-notification-tutorial/
    NSLog(@"[AppleDelegate showAlarm] called");
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.userInfo = notification.userInfo;
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = @"Your alert message";
    localNotification.alertAction = @"AlertButtonCaption";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    //reacts to notification
    NSLog(@"didReceiveLocalNotification");
    //Instantiate new viewcontroller here and segue
    if (application.applicationState == UIApplicationStateInactive) {
        [[UIApplication sharedApplication] cancelLocalNotification:notification];
        
        //if coming from primer, pop to MVC, else pop to RSVC
        for(NSString *key in notification.userInfo){
            NSString *dictKey = [notification.userInfo objectForKey:key];
            NSLog(@"notification userInfo: %@", dictKey);
            dictKey = @"here";
            if ([dictKey isEqualToString:@"approaching"]) {
                NSLog(@"Runner status: approaching");
            }
            else if ([dictKey isEqualToString:@"here"]) {
                //    [application presentLocalNotificationNow:notification];
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                //instantiate all associated VCs
                
                DefaultSettingsViewController *dsvc = (DefaultSettingsViewController *)[sb instantiateViewControllerWithIdentifier:@"defaultSettingsViewController"];
                RoleViewController *rvc = (RoleViewController *)[sb instantiateViewControllerWithIdentifier:@"roleViewController"];
                CheererStartViewController *csvc = (CheererStartViewController *)[sb instantiateViewControllerWithIdentifier:@"cheererStartViewController"];
                MotivatorViewController *mvc = (MotivatorViewController *)[sb instantiateViewControllerWithIdentifier:@"motivatorViewController"];
                RelationshipViewController *rsvc = (RelationshipViewController *)[sb instantiateViewControllerWithIdentifier:@"relationshipViewController"];
                
                //HelperMapViewController *hmvc = (HelperMapViewController *)[sb instantiateViewControllerWithIdentifier:@"HelperMapViewController"];
                // HelperDetailViewController *hdvc = (HelperDetailViewController *)[sb instantiateViewControllerWithIdentifier:@"HelperDetailViewController"];
                
                rsvc.userInfo = notification.userInfo;
                NSLog(@"appDel dictionary is %@", rsvc.userInfo);
                /*
                 for(NSString *key in notification.userInfo){
                 NSLog(@"notification userInfo: %@", [notification.userInfo objectForKey:key]);
                 rsvc.objectId = [notification.userInfo objectForKey:key];
                 }
                 */
                UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
                nav.viewControllers = [NSArray arrayWithObjects:dsvc,csvc,rvc,mvc,rsvc, nil];

                
                [nav popToViewController:rsvc animated:YES];
            }
        }
    }
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground()");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Background networking
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"Background fetch started...");
    
    //---do background fetch here---
    // You have up to 30 seconds to perform the fetch
    
    BOOL downloadSuccessful = YES;
    
    if (downloadSuccessful) {
        //---set the flag that data is successfully downloaded---
        completionHandler(UIBackgroundFetchResultNewData);
    } else {
        //---set the flag that download is not successful---
        completionHandler(UIBackgroundFetchResultFailed);
    }
    
    NSLog(@"Background fetch completed...");
    
}



#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "edu.northwestern.delta.CrowdCheer" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CrowdCheer" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CrowdCheer.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end