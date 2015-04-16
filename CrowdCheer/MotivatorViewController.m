//
//  MotivatorViewController.m
//  CrowdCheer
//
//  Created by Scott Cambo on 3/2/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "MotivatorViewController.h"
#import "RelationshipViewController.h"
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>

static NSString * const detailSegueName = @"RelationshipView";


@interface MotivatorViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, UIAlertViewDelegate>

{
    dispatch_queue_t checkQueue;
}
@property (nonatomic, strong) NSTimer *isCheckingRunners;
@property (nonatomic, strong) NSTimer *didRunnerExit;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (weak, nonatomic) IBOutlet UILabel *lonLabel;
@property (weak, nonatomic) IBOutlet UILabel *latLabel;
@property (strong, nonatomic) NSString *runnerObjId;
@property (weak, nonatomic) IBOutlet UIButton *viewPrimerButton;

@property (weak, nonatomic) PFUser *currentRunnerToCheer;
@property (weak, nonatomic) PFUser *thisUser;
@end

@implementation MotivatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"MotivatorViewController.viewDidLoad()");
    //this is what initializes the timer and gets it started
    self.isCheckingRunners = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                selector:@selector(eachSecond) userInfo:nil repeats:YES];
    [self startLocationUpdates];
    self.thisUser = [PFUser currentUser];
    self.viewPrimerButton.hidden = YES;
    self.latLabel.hidden = YES;
    self.lonLabel.hidden = YES;

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scheduleNotification {
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    
    notif.timeZone = [NSTimeZone defaultTimeZone];
    
    notif.alertBody = @"Body";
    notif.alertAction = @"AlertButtonCaption";
    notif.soundName = UILocalNotificationDefaultSoundName;
    notif.applicationIconBadgeNumber = 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
}


- (void)eachSecond
{
    NSLog(@"eachSecond()...");
    NSLog(@"Checking for runners...");
    
    
    //First check for runners who have updated information recently
    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];
    [timeQuery orderByAscending:@"updatedAt"];
    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *possibleNearbyRunners, NSError *error) {
        if (!error) {
            // The find succeeded. The first 100 objects are available in objects
            
            //get locations for all these possibly nearby runners and check distance
            for (PFObject *possible in possibleNearbyRunners) {
                PFGeoPoint *point = [possible objectForKey:@"location"];
                
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //hardcode runner data here to test on simulator
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations.lastObject]; //in meters
                int radius = 200;
                if (dist < radius){
                    NSLog(@"Found a runner!");
                    PFUser *user = possible[@"user"];
                    NSLog(@"Runner we found is %@", user.objectId);
                    [user fetchIfNeeded];
                    NSString *runnerName = [NSString stringWithFormat:@"%@",[user objectForKey:@"name"]];
                    NSLog(runnerName);
                    NSString *runnerObjId = [user valueForKeyPath:@"objectId"];
                    self.runnerObjId = runnerObjId;
                    NSLog(@"Runner Object ID is %@", self.runnerObjId);
                    
                    NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
                    UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:self cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];
                    
                    NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", nil];
                    NSLog(@"MVC dictionary is %@", runnerDict);
                    
                    [self.isCheckingRunners invalidate];
                    self.didRunnerExit = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                                         selector:@selector(checkRunnerLocation) userInfo:nil repeats:YES];
                    
                    //quick way to save for RelationshipViewController to use
                    self.currentRunnerToCheer = [PFObject objectWithClassName:@"currentRunnerToCheer"];
                    [self.currentRunnerToCheer setObject:user forKey:@"runner"];
                    [self.currentRunnerToCheer saveInBackground];
                    
                    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
                    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
                    {
                        // This code sends notification to didFinishLaunchingWithOptions in AppDelegate.m
                        // userInfo can include the dictionary above called runnerDict
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated"
                                                                            object:self
                                                                          userInfo:runnerDict];
                        NSLog(@"%@ in backgorund thread", self.runnerObjId);
                    } else {
                        
                        NSLog(@"MotivatorViewController was loaded when runner trigger occurred");
                        [cheerAlert show];
                        //                    self.runnerObjId = runnerObjId;
                        //                    NSLog(@"%@ in main thread", runnerObjId);
                        
                    }
                    //if there is a runner within the radius, break and do not notify again
                    break;
                }
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    

    //dispatch_async(checkQueue,^{[self checkForRunners];});
}

- (void)checkRunnerLocation {
    //get runner to cheerer id
    //query parse for distance
    
    PFQuery *query = [PFQuery queryWithClassName:@"RunnerLocation"];
    [query orderByAscending:@"updatedAt"];
    [query whereKey:@"user" equalTo:self.currentRunnerToCheer];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            // Do something with the found objects
            
            PFGeoPoint *point = [objects.firstObject objectForKey:@"location"];
            CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //hardcode runner data here to test on simulator
            CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations.lastObject]; //in meters
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

//- (void)checkForRunners
//{
//    NSLog(@"Checking for runners...");
//    
//    
//    //First check for runners who have updated information recently
//    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
//    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
//    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];
//    [timeQuery orderByAscending:@"updatedAt"];
//    NSArray *possibleNearbyRunners = [timeQuery findObjects];
//    
//    //get locations for all these possibly nearby runners and check distance
//    for (PFObject *possible in possibleNearbyRunners) {
//        PFGeoPoint *point = [possible objectForKey:@"location"];
//        
//        CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //hardcode runner data here to test on simulator
//        CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations.lastObject]; //in meters
//        if (dist < 200){
//            NSLog(@"Found a runner!");
//            PFUser *user = possible[@"user"];
//            NSLog(@"Runner we found is %@", user.objectId);
//            [user fetchIfNeeded];
//            NSString *runnerName = [NSString stringWithFormat:@"%@",[user objectForKey:@"name"]];
//            NSLog(runnerName);
//            NSString *runnerObjId = [user valueForKeyPath:@"objectId"];
//            self.runnerObjId = runnerObjId;
//            NSLog(@"Runner Object ID is %@", self.runnerObjId);
//                                     
//            NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
//            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:self cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];
//            
//            NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", nil];
//            NSLog(@"MVC dictionary is %@", runnerDict);
//            
//            [self.isCheckingRunners invalidate];
//            
//            //quick way to save for RelationshipViewController to use
//            PFObject *currentRunnerToCheer = [PFObject objectWithClassName:@"currentRunnerToCheer"];
//            [currentRunnerToCheer setObject:user forKey:@"runner"];
//            [currentRunnerToCheer saveInBackground];
//            
//            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//            if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
//            {
//                // This code sends notification to didFinishLaunchingWithOptions in AppDelegate.m
//                // userInfo can include the dictionary above called runnerDict
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated"
//                                                                    object:self
//                                                                  userInfo:runnerDict];
//                NSLog(@"%@ in backgorund thread", self.runnerObjId);
//            } else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSLog(@"MotivatorViewController was loaded when runner trigger occurred");
//                    [cheerAlert show];
////                    self.runnerObjId = runnerObjId;
////                    NSLog(@"%@ in main thread", runnerObjId);
//                    
//                });
//            }
//            break;
//        }
//    }
//}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"button clicked!!!!");
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    NSLog(@"%d", buttonIndex);
    if ([buttonTitle isEqualToString:@"Cheer!"]) {
        NSLog(@"the button is equal to cheer");
        
        [self performSegueWithIdentifier:@"relationshipSegue" sender:self];
        
    }
}


- (void)startLocationUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.activityType = CLActivityTypeFitness;
    
    // Movement threshold for new events.
    self.locationManager.distanceFilter = 10; // meters
    
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    
    PFGeoPoint *loc  = [PFGeoPoint geoPointWithLocation:newLocation];

    PFObject *cheerLocation = [PFObject objectWithClassName:@"CheerLocation"];
    [cheerLocation setObject:[[NSDate alloc] init] forKey:@"time"];
    [cheerLocation setObject:loc forKey:@"location"];
    [cheerLocation setObject:self.thisUser forKey:@"user"];
    NSLog(@"CheerLocation is %@", loc);
    
    [cheerLocation saveInBackground];
    /**
    if (!checkQueue){
        checkQueue = dispatch_queue_create("com.crowdcheer.runnerCheck", NULL);
    }
     */

}

- (void)viewWillDisappear:(BOOL)animated
{
    //[super viewWillDisappear:<#animated#>];
    [self.isCheckingRunners invalidate];
}

- (void)showAlarm:(NSNotification *)notification {
    // showAlarm gets called from notification that is registered in didFinishLaunchingWithOptions at the top of this class
    // this code was borrowed from http://www.appcoda.com/ios-programming-local-notification-tutorial/
    NSLog(@"[AppleDelegate showAlarm] called");
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = @"Your alert message";
    localNotification.alertAction = @"AlertButtonCaption";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"========here here ======");
    // Get the new view controller using [segue destinationViewController].
    //    if ([sender isKindOfClass:[UITableViewCell class]]) {
    //    self.myIndexPath = [self.tableView indexPathForCell:sender];
    if([segue.identifier isEqualToString:@"relationshipSegue"]) {
        if([segue.destinationViewController isKindOfClass:[RelationshipViewController class]]) {
            NSLog(@"================Segueing===============");
            RelationshipViewController *rvc = [segue destinationViewController];
            rvc.runnerObjId = self.runnerObjId; //sets the property declared in RelationshipViewController.h
            rvc.fromAlert = YES;
            NSLog(@"here is the object ID: %@",self.runnerObjId);
        }
    }
    //    }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end