//
//  MotivatorViewController.m
//  CrowdCheer
//
//  Created by Scott Cambo on 3/2/15.
//  Modified by Leesha Maliakal
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "MotivatorViewController.h"
#import "RelationshipViewController.h"
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>
#import <AudioToolbox/AudioServices.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <EstimoteSDK/EstimoteSDK.h>

static NSString * const detailSegueName = @"RelationshipView";


@interface MotivatorViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, ESTBeaconManagerDelegate>

{
    dispatch_queue_t checkQueue;
}
@property (nonatomic, strong) NSTimer *isCheckingRunners;
@property (nonatomic, strong) NSTimer *didRunnerExit;
@property (nonatomic, strong) NSTimer *hapticTimer;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
//@property (nonatomic, strong) ESTUtilityManager *utilityManager;
@property (nonatomic, strong) CLLocation *locations;
@property (weak, nonatomic) IBOutlet UILabel *lonLabel;
@property (weak, nonatomic) IBOutlet UILabel *latLabel;
@property (weak, nonatomic) IBOutlet UILabel *distLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;
@property (strong, nonatomic) NSString *runnerObjId;
@property (weak, nonatomic) IBOutlet UIButton *viewPrimerButton;

@property int major;
@property int minor;
@property int radius1;
@property int radius2;
@property int radius3;
@property int radius4;
@property int radius5;
@property int radius6;
@property int radius7;

@property int radiusInner;
@property int radiusMid;
@property int radiusOuter;
@property int radiusNotify;

@property (weak, nonatomic) PFUser *thisUser;
@property (weak, nonatomic) PFUser *runner;
@property (weak, nonatomic) NSUUID *uuid;

@end

@implementation MotivatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.radiusInner = 15; //15
//    self.radiusMid = 30;//50
//    self.radiusOuter = 60;//100
//    self.radiusNotify = 100;//150
    
    //radius in meters, smaller index = closer
    self.radius1 = 10;
    self.radius2 = 50;
    self.radius3 = 100;
    self.radius4 = 200;
    self.radius5 = 300;
    self.radius6 = 400;
    self.radius7 = 500;
    
    
    // Do any additional setup after loading the view.
    NSLog(@"MotivatorViewController.viewDidLoad()");
    //this is what initializes the timer and gets it started
    self.isCheckingRunners = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                            selector:@selector(eachSecond) userInfo:nil repeats:YES];
    //    self.didRunnerExit = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
    //                                                        selector:@selector(checkRunnerLocation) userInfo:nil repeats:YES];
    [self startLocationUpdates];
    self.thisUser = [PFUser currentUser];
    self.viewPrimerButton.hidden = YES;
    self.latLabel.hidden = NO;
    self.lonLabel.hidden = NO;
    self.distLabel.hidden = NO;
   
    //location
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
//    //bluetooth
//    self.utilityManager = [[ESTUtilityManager alloc] init];
//    self.utilityManager.delegate = self;
    

//    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
//                                                                            major:17784
//                                                                           identifier:@"EstimoteSampleRegion"];
//    
//    // start looking for Estimote beacons in region
//    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
//
//    //location
//    [self.beaconManager requestWhenInUseAuthorization];
//    [self.beaconManager startMonitoringForRegion:region];
//    [self.beaconManager startRangingBeaconsInRegion:region];
    
//    //bluetooth
//    [self.utilityManager startEstimoteBeaconDiscovery];
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

    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                     major:17784
                                                                identifier:@"EstimoteSampleRegion"];
    
    // start looking for Estimote beacons in region
    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
    
    //location
    [self.beaconManager requestWhenInUseAuthorization];
    [self.beaconManager startMonitoringForRegion:region];
    [self.beaconManager startRangingBeaconsInRegion:region];
    
    
    //First check for runners who have updated information recently
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    
    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];
    [timeQuery orderByAscending:@"updatedAt"];
    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *possibleNearbyRunners, NSError *error) {
        if (!error) {
            // The find succeeded. The first 100 objects are available in objects
            
            //get locations for all these possibly nearby runners and check distance
            for (PFObject *possible in possibleNearbyRunners) {
                NSLog(@"Looping through runners...");
                //getting location for a runner object
                PFGeoPoint *point = [possible objectForKey:@"location"];
                //converting location to CLLocation
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; //in meters
                NSLog(@"possible's dist: %f", dist);
                self.distLabel.text = [NSString stringWithFormat:@"Dist(ft): %f", dist];
                self.latLabel.text = [NSString stringWithFormat:@"Lat: %f", point.latitude];
                self.lonLabel.text = [NSString stringWithFormat:@"Lon: %f", point.longitude];
                NSLog(@"updated dist label to: %f", dist);
                
                //based on the distance between me and our possible runner, do the following:
                
                if ((dist <= self.radius7) && (dist > self.radius6)) {
                    //between radius 6 and 7
                    //notify
                    //UI update - Runner is x meters and y minutes away
                    NSLog(@"Entered %d m", self.radius7);
                    self.rangeLabel.text = [NSString stringWithFormat:@"Runner is %f meters away", dist];
                    PFUser *runner = possible[@"user"];
                    [runner fetchIfNeeded];
                    NSLog(@"sending primer for runner %@", runner.objectId);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self runnerApproaching:runner :dist];
                    });
                }
                else if ((dist <= self.radius6) && (dist > self.radius5)) {
                    //between radius 5 and 6
                    //notify
                    //UI update
                    NSLog(@"Entered %d m", self.radius6);
                    self.rangeLabel.text = [NSString stringWithFormat:@"Runner is %f meters away", dist];
                    PFUser *runner = possible[@"user"];
                    [runner fetchIfNeeded];
                    NSLog(@"sending primer for runner %@", runner.objectId);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self runnerApproaching:runner :dist];
                    });
                }
                else if ((dist <= self.radius5) && (dist > self.radius4)) {
                    //between radius 4 and 5
                    //notify
                    //UI update
                    NSLog(@"Entered %d m", self.radius5);
                    self.rangeLabel.text = [NSString stringWithFormat:@"Runner is %f meters away", dist];
                    PFUser *runner = possible[@"user"];
                    [runner fetchIfNeeded];
                    NSLog(@"sending primer for runner %@", runner.objectId);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self runnerApproaching:runner :dist];
                    });
                }
                else if ((dist <= self.radius4) && (dist > self.radius3)) {
                    //between radius 3 and 4
                    //notify
                    //UI update
                    NSLog(@"Entered %d m", self.radius4);
                    self.rangeLabel.text = [NSString stringWithFormat:@"Runner is %f meters away", dist];
                    PFUser *runner = possible[@"user"];
                    [runner fetchIfNeeded];
                    NSLog(@"sending primer for runner %@", runner.objectId);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self runnerApproaching:runner :dist];
                    });
                }
                else if ((dist <= self.radius3) && (dist > self.radius2)) {
                    //between radius 2 and 3
                    //notify with primer
                    NSLog(@"Entered %d m", self.radius3);
                    PFUser *runner = possible[@"user"];
                    [runner fetchIfNeeded];
                    NSLog(@"sending primer for runner %@", runner.objectId);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self foundRunner:runner];
                    });
                }
                else if ((dist <= self.radius2) && (dist > self.radius1)) {
                    //betweem radius 1 and 2
                    //beacon & primer
                    NSLog(@"Entered %d m", self.radius2);
                }
                else if (dist <= self.radius1) {
                    //inside radius 1
                    //beacon & primer
                    NSLog(@"Entered %d m", self.radius1);
                }
                else {
                     //outside range
                    NSLog(@"Out of range");
                }
//                
//                if ((self.radiusOuter < dist) && (dist <= self.radiusNotify)) {
//                    //runner entered 150ft radius
//                    //notify cheerer
//                    PFUser *runner = possible[@"user"];
//                    [runner fetchIfNeeded];
//                    NSLog(@"runner found is %@", runner.objectId);
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self foundRunner:runner];
//                    });
//                }
//                
//                else if ((self.radiusMid < dist) && (dist <= self.radiusOuter)) {
//                    NSLog(@"runner entered 100ft radius");
//                    //buzz every 7 second
//                   // [self.hapticTimer invalidate]; //invalidate prev haptic timer
//                    self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
//                                                                      selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                }
//                
//                else if ((self.radiusInner < dist) && (dist <= self.radiusMid)){
//                    NSLog(@"runner entered 50ft radius");
//                    //buzz every 3 seconds
//                //    [self.hapticTimer invalidate]; //invalidate prev haptic timer
//                    self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
//                                                                      selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                }
//                
//                else if (dist <= self.radiusInner) {
//                    NSLog(@"runner entered 15ft radius");
//                    //buzz every 0.5 seconds
//                    self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.2) target:self
//                                                                      selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                }
                
                break; //exiting for loop
            }
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }]; //end of find objects in background with block
    //checking if we found runner
};

-(void) runnerApproaching:(PFUser*)runner :(const double)distance {
    NSLog(@"runnerApproaching called");
    if (runner != nil) {
        NSLog(@"runner = %@", runner);
        
        self.runner = runner;
        NSString *runnerName = [NSString stringWithFormat:@"%@",[self.runner objectForKey:@"name"]];
        NSString *runnerObjId = [self.runner valueForKeyPath:@"objectId"];
        self.runnerObjId = runnerObjId;
        
        NSString *alertMess =  [runnerName stringByAppendingFormat:@" is %fm away!", distance];
        NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", nil];
        
//        //saving parse data for when cheerer receives notification and for which runner
//        PFObject *cheererNotification = [PFObject objectWithClassName:@"cheererWasNotified"];
//        [cheererNotification setObject:self.runner forKey:@"runner"];
//        [cheererNotification setObject:self.thisUser forKey:@"cheerer"];
//        NSLog(@"self.runner is %@", self.runner);
//        [cheererNotification saveInBackground];
//        NSLog(@"cheererNotification is %@", cheererNotification);
        
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        NSLog(@"application state is %d", state);
        if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
        {
            // This code sends notification to didFinishLaunchingWithOptions in AppDelegate.m
            // userInfo can include the dictionary above called runnerDict
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated"
                                                                object:self
                                                              userInfo:runnerDict];
            
            NSLog(@" notifying about %@ from background", self.runnerObjId);
        } else {
            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            NSLog(@"about to display cheerAlert");
            [cheerAlert show];
            //                    self.runnerObjId = runnerObjId;
            //                    NSLog(@"%@ in main thread", runnerObjId);
            
        }
        
    } else {
        NSLog(@"Runner was nil");
    }
    
}

-(void) foundRunner:(PFUser*)runner{
    NSLog(@"foundRunner called");
    if (runner != nil) {
        NSLog(@"runner = %@", runner);
        
        //        [runner fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //            if(!error) {
        //                NSLog(@"runner we fetched is %@", self.runner);
        //
        //            }
        //            else {
        //                NSLog(@"ERR: could not fetch");
        //            }
        //        }]; // fetching runner in background is done
        self.runner = runner;
        NSString *runnerName = [NSString stringWithFormat:@"%@",[self.runner objectForKey:@"name"]];
        NSString *runnerObjId = [self.runner valueForKeyPath:@"objectId"];
        self.runnerObjId = runnerObjId;
        
        NSString *alertMess =  [runnerName stringByAppendingFormat:@" is coming, get ready to cheer!"];
//        NSString *alertMess =  [@"Get ready to cheer for %@!", runnerName];
        NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", nil];
        
        //saving parse data for when cheerer receives notification and for which runner
        PFObject *cheererNotification = [PFObject objectWithClassName:@"cheererWasNotified"];
        [cheererNotification setObject:self.runner forKey:@"runner"];
        [cheererNotification setObject:self.thisUser forKey:@"cheerer"];
        NSLog(@"self.runner is %@", self.runner);
        [cheererNotification saveInBackground];
        NSLog(@"cheererNotification is %@", cheererNotification);
        
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        NSLog(@"application state is %d", state);
        if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
        {
            // This code sends notification to didFinishLaunchingWithOptions in AppDelegate.m
            // userInfo can include the dictionary above called runnerDict
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated"
                                                                object:self
                                                              userInfo:runnerDict];
            
            NSLog(@" notifying about %@ from background", self.runnerObjId);
        } else {
            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            NSLog(@"about to display cheerAlert");
            [cheerAlert show];
            //                    self.runnerObjId = runnerObjId;
            //                    NSLog(@"%@ in main thread", runnerObjId);
            
        }
        
        [self.isCheckingRunners invalidate];
        NSLog(@"invalidated isCheckingRunners");
        self.didRunnerExit = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                            selector:@selector(checkRunnerLocation:) userInfo:runner repeats:YES];
        
    } else {
        NSLog(@"Runner was nil");
    }
    
}


- (void)checkRunnerLocation:(PFUser*)runner {
    //get runner to cheerer id
    //query parse for distance
    NSLog(@"checkRunnerLocation called");
    NSLog(@"timer is passing the username: %@", self.runner.username);
    if (self.runner == nil) {
        NSLog(@"runner is nil");
    }
    else {
        NSLog(@"runner found, name is %@", self.runner.username);
        //PFQuery *query = [PFQuery queryWithClassName:@"User"];
        // [query whereKey:@"objectId" equalTo:runner];
        
        PFQuery *query = [PFQuery queryWithClassName:@"RunnerLocation"];
        [query orderByDescending: @"updatedAt"];
        //convert user key to string instead of pointer
        [query whereKey:@"user" equalTo:self.runner];
        
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // The find succeeded.
                // Do something with the found objects
                NSString *objId = [objects.firstObject valueForKeyPath:@"objectId"];
                
                NSLog(@"findingRunner objId == %@", objId);
                PFGeoPoint *point = [objects.firstObject valueForKeyPath:@"location"];
                //NSLog(@"%@", objects.firstObject);
                //NSLog(objects);
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //hardcode runner data here to test on simulator
                NSLog(@"Lat : %f", point.latitude);
                NSLog(@"Lon : %f", point.longitude);
                if ( (point.latitude != 0) && (point.longitude != 0)){
                    CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; //in meters
                    NSLog(@"dist : %f", dist);
                    if (dist > self.radiusOuter){
                        NSLog(@"runner is gone!");
                        [self.didRunnerExit invalidate];
                        [self.hapticTimer invalidate];
                    }
                }
            } else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
        }];
    }
}

- (void)setVibrations{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    NSLog(@"vibrate");
}


//location
-(void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(CLBeaconRegion *)region
{
    NSLog(@"beacon count: %lu", (unsigned long)beacons.count);
    if([beacons count] > 0)
    {
        // beacon array is sorted based on distance
        // closest beacon is the first one
        CLBeacon* closestBeacon = [beacons objectAtIndex:0];
        
        // calculate and set new y position
        //  switch (closestBeacon.ibeacon.proximity)
        switch (closestBeacon.proximity)
        {
            case CLProximityUnknown:
                self.rangeLabel.text = @"Runner is out of beacon range!";
                break;
            case CLProximityImmediate:
                self.rangeLabel.text = @"Runner is HERE! (0-8'')";
                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
                break;
            case CLProximityNear:
                self.rangeLabel.text = @"Runner is NEAR (8'' - 6.5')";
                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(2.0) target:self
                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
                break;
            case CLProximityFar:
                self.rangeLabel.text = @"Runner is FAR (6.5-230')";
                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self
                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
                break;
                
            default:
                break;
        }
    }
}
//
////bluetooth
//- (void)utilityManager:(ESTUtilityManager *)manager
//    didDiscoverBeacons:(NSArray *)beacons
//{
//    if (beacons.count > 0)
//    {
//        ESTBluetoothBeacon *closestBeacon = [beacons objectAtIndex:0];
//        
//        switch (closestBeacon.rssi)
//        {
//            case CLProximityUnknown:
//                self.rangeLabel.text = @"Runner is out of beacon range!";
//                break;
//            case CLProximityImmediate:
//                self.rangeLabel.text = @"Runner is HERE! (0-8'')";
//                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
//                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                break;
//            case CLProximityNear:
//                self.rangeLabel.text = @"Runner is NEAR (8'' - 6.5')";
//                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(2.0) target:self
//                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                break;
//            case CLProximityFar:
//                self.rangeLabel.text = @"Runner is FAR (6.5-230')";
//                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self
//                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                break;
//                
//            default:
//                break;
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
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    self.locations = newLocation;
    PFGeoPoint *loc  = [PFGeoPoint geoPointWithLocation:newLocation];
    
    PFObject *cheerLocation = [PFObject objectWithClassName:@"CheererLocation"];
    [cheerLocation setObject:[[NSDate alloc] init] forKey:@"time"];
    [cheerLocation setObject:loc forKey:@"location"];
    [cheerLocation setObject:self.thisUser forKey:@"user"];
    NSLog(@"CheererLocation is %@", loc);
    
    [cheerLocation saveInBackground];
    /**
     if (!checkQueue){
     checkQueue = dispatch_queue_create("com.crowdcheer.runnerCheck", NULL);
     }
     */
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[super viewWillDisappear:];
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