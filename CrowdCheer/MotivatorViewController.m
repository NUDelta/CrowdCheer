//
//  MotivatorViewController.m
//  CrowdCheer
//
//  Created by Scott Cambo on 3/2/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "MotivatorViewController.h"
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>

static NSString * const detailSegueName = @"RelationshipView";


@interface MotivatorViewController () <UIActionSheetDelegate, CLLocationManagerDelegate>{
    dispatch_queue_t checkQueue;
}
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (weak, nonatomic) IBOutlet UILabel *lonLabel;
@property (weak, nonatomic) IBOutlet UILabel *latLabel;

@property (weak, nonatomic) PFUser *runnerToCheer;
@end

@implementation MotivatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"MotivatorViewController.viewDidLoad()");
    
    //this is what initializes the timer and gets it started
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                selector:@selector(eachSecond) userInfo:nil repeats:YES];
    [self startLocationUpdates];
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
    PFGeoPoint *loc  = [PFGeoPoint geoPointWithLocation:self.locations.lastObject];
    PFUser *thisUser = [PFUser currentUser];
    
    PFObject *cheerLocation = [PFObject objectWithClassName:@"CheerLocation"];
    [cheerLocation setObject:[[NSDate alloc] init] forKey:@"time"];
    [cheerLocation setObject:loc forKey:@"location"];
    [cheerLocation setObject:thisUser forKey:@"user"];
    
    [cheerLocation saveInBackground];
    if (!checkQueue){
        checkQueue = dispatch_queue_create("com.crowdcheer.runnerCheck", NULL);
    }
    dispatch_async(checkQueue,^{[self checkForRunners];});
}

- (void)checkForRunners
{
    NSLog(@"Checking for runners...");
    
    
    //First check for runners who have updated information recently
    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];
    [timeQuery orderByAscending:@"updatedAt"];
    NSArray *possibleNearbyRunners = [timeQuery findObjects];
    
    //get locations for all these possibly nearby runners and check distance
    for (PFObject *possible in possibleNearbyRunners) {
        PFGeoPoint *point = [possible objectForKey:@"location"];
        
        CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //hardcode runner data here to test on simulator
        CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations.lastObject]; //in meters
        if (dist < 200){
            NSLog(@"Found a runner!");
            PFUser *user = possible[@"user"];
            NSLog(@"Runner we found is %@", user.objectId);
            [user fetchIfNeeded];
            NSString *runnerName = [NSString stringWithFormat:@"%@",[user objectForKey:@"name"]];
            NSLog(runnerName);
            NSString *runnerObjID = user.objectId;
            NSLog(@"Runner Object ID is %@", runnerObjID);
                                     
            NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:nil cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];
            
            NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:runnerObjID, @"user", nil];
            NSLog(@"MVC dictionary is %@", runnerDict);
            
            [self.timer invalidate];
            
            //quick way to save for RelationshipViewController to use
            PFObject *currentRunnerToCheer = [PFObject objectWithClassName:@"currentRunnerToCheer"];
            [currentRunnerToCheer setObject:user forKey:@"runner"];
            [currentRunnerToCheer saveInBackground];
            
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
            {
                // This code sends notification to didFinishLaunchingWithOptions in AppDelegate.m
                // userInfo can include the dictionary above called runnerDict
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated"
                                                                    object:self
                                                                  userInfo:runnerDict];
            
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSLog(@"MotivatorViewController was loaded when runner trigger occurred");
                    [cheerAlert show];
                    
                });
            }
        }
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
    for (CLLocation *newLocation in locations) {
        if (newLocation.horizontalAccuracy < 20) {
            self.latLabel.text = [NSString stringWithFormat:@"Lat : %f", newLocation.coordinate.latitude];
            self.lonLabel.text = [NSString stringWithFormat:@"Lon : %f" , newLocation.coordinate.longitude];
            [self.locations addObject:newLocation];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.timer invalidate];
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end