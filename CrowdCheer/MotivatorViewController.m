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
#import <AudioToolbox/AudioServices.h>

static NSString * const detailSegueName = @"RelationshipView";


@interface MotivatorViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, UIAlertViewDelegate>

{
    dispatch_queue_t checkQueue;
}
@property (nonatomic, strong) NSTimer *isCheckingRunners;
@property (nonatomic, strong) NSTimer *didRunnerExit;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *locations;
@property (weak, nonatomic) IBOutlet UILabel *lonLabel;
@property (weak, nonatomic) IBOutlet UILabel *latLabel;
@property (strong, nonatomic) NSString *runnerObjId;
@property (weak, nonatomic) IBOutlet UIButton *viewPrimerButton;
@property int radius;

@property (weak, nonatomic) PFUser *thisUser;
@property (weak, nonatomic) PFUser *runner;

@end

@implementation MotivatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.radius = 200;
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
    //__block PFUser *runnerLocal;
    
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
                //getting location for a runner object
                PFGeoPoint *point = [possible objectForKey:@"location"];
                //converting location to CLLocation
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
                NSLog(@"possible's runnerLoc is storing: %@", runnerLoc);
                
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; //in meters
                NSLog(@"self.locations is storing: %@", self.locations);
                NSLog(@"possible's dist is storing: %f", dist);
                if (dist < self.radius){
                    NSLog(@"runner entered radius");
                    //NSLog(@"a runner's dist < radius");
                    NSLog(@"RunnerLocation.objid == %@", possible.objectId);
                    PFUser *runner = possible[@"user"];
                    [runner fetchIfNeeded];
//                    NSLog(@"Runner we found is %@", self.runner.objectId);
                    NSLog(@"eachSecond : runner found is %@", runner.objectId);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self foundRunner:runner];
                    });
                    break; //exiting for loop
                }
            }
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }]; //end of find objects in background with block
    //checking if we found runner

    
};

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
        //stopping first timer to check runners, starting timer for did runner exit
        NSString *runnerName = [NSString stringWithFormat:@"%@",[self.runner objectForKey:@"name"]];
        NSString *runnerObjId = [self.runner valueForKeyPath:@"objectId"];
        self.runnerObjId = runnerObjId;
        //NSLog(@"Runner Object ID is %@", self.runnerObjId);
        
        NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];

        
        NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", nil];
        //NSLog(@"MVC dictionary is %@", runnerDict);
        
        
        //saving data for when cheerer receives notification and for whom
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
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            NSLog(@" notifying about %@ from background", self.runnerObjId);
        } else {
            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:self cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];
            NSLog(@"about to display cheerAlert");
            [cheerAlert show];
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            //                    self.runnerObjId = runnerObjId;
            //                    NSLog(@"%@ in main thread", runnerObjId);
            
        }
        //if there is a runner within the radius, break and do not notify again
        
        
        [self.isCheckingRunners invalidate];
        NSLog(@"invalidated isCheckingRunners");
        
        //                    self.didRunnerExit.fire;
        //                    NSLog(@"is timer valid? %d", self.didRunnerExit.isValid);
        //                    NSLog(@"last fire date %@", self.didRunnerExit.fireDate);
        //[self performSelectorOnMainThread:@selector(createTimer) withObject:nil waitUntilDone:YES];
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
                if (dist > self.radius){
                    NSLog(@"runner is gone!");
                    
                }
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    }
}


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