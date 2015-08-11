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
#import <MapKit/MapKit.h>
#import <AudioToolbox/AudioServices.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <EstimoteSDK/EstimoteSDK.h>

static NSString * const detailSegueName = @"RelationshipView";

@interface MotivatorViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, ESTBeaconManagerDelegate, MKMapViewDelegate>

{
    dispatch_queue_t checkQueue;
}
@property (nonatomic, strong) NSTimer *isCheckingRunners;
@property (nonatomic, strong) NSTimer *isTrackingRunner;
@property (nonatomic, strong) NSTimer *isUpdatingDistance;
@property (nonatomic, strong) NSTimer *didRunnerExit;
@property (nonatomic, strong) NSTimer *hapticTimer;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) CLLocation *locations;
@property (nonatomic, readwrite) MKPolyline *polyline; //your line
@property (nonatomic, readwrite) MKPolylineView *lineView; //your line view
@property (nonatomic, strong) NSMutableArray *runnerPath;
@property (weak, nonatomic) IBOutlet UILabel *lonLabel;
@property (weak, nonatomic) IBOutlet UILabel *latLabel;
@property (weak, nonatomic) IBOutlet UILabel *distLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSString *runnerObjId;
@property (weak, nonatomic) IBOutlet UIButton *cheerButton;
@property (nonatomic, strong) NSMutableArray *runnerDist;

@property int radius1;
@property int radius2;
@property int radius3;
@property int radius4;
@property int radius5;
@property int radius6;
@property int radius7;
@property int major;
@property int minor;

@property (weak, nonatomic) PFUser *cheerer;
@property (weak, nonatomic) PFUser *runner;
@property (weak, nonatomic) NSUUID *uuid;

@end

@implementation MotivatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //radius in meters, smaller index = closer to runner
    self.radius1 = 10; //10
    self.radius2 = 50; //50
    self.radius3 = 100;//100
    self.radius4 = 200;//200
    self.radius5 = 300;//300
    self.radius6 = 400;//400
    self.radius7 = 500;//500
    
    
    // Do any additional setup after loading the view.
    NSLog(@"MotivatorViewController.viewDidLoad()");
    
    //Step 1a: initialize isCheckingRunners, call findEachSecond every 1s
    NSLog(@"isCheckingRunners started");
    self.isCheckingRunners = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                            selector:@selector(findEachSecond) userInfo:nil repeats:YES];
    [self startLocationUpdates];
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    self.cheerer = [PFUser currentUser];
    
    //For debugging purposes:
    self.cheerButton.hidden = YES;
    self.latLabel.hidden = YES;
    self.lonLabel.hidden = YES;
    self.distLabel.hidden = YES;
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scheduleNotification {
    //don't use this
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    
    notif.timeZone = [NSTimeZone defaultTimeZone];
    
    notif.alertBody = @"Body";
    notif.alertAction = @"AlertButtonCaption";
    notif.soundName = UILocalNotificationDefaultSoundName;
    notif.applicationIconBadgeNumber = 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
}

//findEachSecond()
- (void)findEachSecond{
    NSLog(@"findEachSecond()...");
    //Step 1b: Every second, look for potential runners to cheer. Pick a runner if they are 400-500m away.
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];//First check for runners who have updated information recently
    [timeQuery orderByAscending:@"updatedAt"];
    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *possibleNearbyRunners, NSError *error) { //if there are any objects found, create an array and execute block
        if (!error) {
            // The find succeeded. The first 100 objects are available
            for (PFObject *possible in possibleNearbyRunners) { //loop through all these possibly nearby runners and check distance
                NSLog(@"Looping through runners...");
                PFGeoPoint *point = [possible objectForKey:@"location"]; //getting location for a runner object
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //converting location to CLLocation
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; // distance in meters
                NSLog(@"possible's dist: %f", dist);
                self.distLabel.text = [NSString stringWithFormat:@"Dist(ft): %f", dist];
                self.latLabel.text = [NSString stringWithFormat:@"Lat: %f", point.latitude];
                self.lonLabel.text = [NSString stringWithFormat:@"Lon: %f", point.longitude];
                NSLog(@"updated dist label to: %f", dist);
                
                //based on the distance between me and our possible runner, do the following:
                if ((dist <= self.radius7) && (dist > self.radius6)) {  //between radius 6 and 7
                    NSLog(@"Entered %d m", self.radius7);
                    PFUser *runner = possible[@"user"];
                    [runner fetchIfNeeded];
                    int distInt = (int)dist;
//                    [self.runnerDist addObject:[NSNumber numberWithDouble:dist]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self runnerApproaching:runner :dist]; //notify
                    });
                }
                else {
                    
                    NSLog(@"Runner out of range"); //outside range
                }
                break; //exiting for loop
            }
            
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);  // Log details of the failure
        }
    }]; //end of find objects in background with block
    NSLog(@"No runners found");
}

//trackEachSecond(radius shells, runner)
- (void)trackEachSecond:(NSTimer*)timer {
    NSLog(@"trackEachSecond()...");
   
    NSDictionary *trackESArgs = (NSDictionary *)[timer userInfo];
    NSLog(@"trackESArgs: %@", trackESArgs);
    PFUser *runnerTracked = [trackESArgs objectForKey:@"runner"];
    
    NSInteger radiusOuter = [[trackESArgs objectForKey:@"radiusOuter"] integerValue];
    NSInteger radiusInner = [[trackESArgs objectForKey:@"radiusInner"] integerValue];
    NSLog(@"radiusouter: %ld radiusinner: %ld", (long)radiusOuter, (long)radiusInner);
    
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    //Find any recent location updates from our runner
    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
    [timeQuery whereKey:@"user" equalTo:runnerTracked];
    [timeQuery orderByDescending:@"updatedAt"];
    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *runnerLocations, NSError *error) {
        if (!error) {
            // The find succeeded. The first 100 objects are available
            //loop through all these possibly nearby runners and check distance
            NSMutableArray *runnerPath = [NSMutableArray array];
            for (PFObject *runnerLocEntry in runnerLocations) {
                NSLog(@"Looping through runner's locations...");
                NSLog(@"runnerLocEntry: %@", runnerLocEntry);
                //getting location for a runner object
                PFGeoPoint *point = [runnerLocEntry objectForKey:@"location"];
                //converting location to CLLocation
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
                //storing in location array
                [runnerPath addObject:runnerLoc];
                
                //calculate distance
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; //in meters
                NSLog(@"runnerLocEntry's dist: %f", dist);
//                NSLog(@"updated dist label to: %f", dist);
                //based on the distance between me and our possible runner, do the following:
                NSNumber *radiusO;
                NSNumber *radiusI;
                
                if ((dist <= self.radius6) && (dist > self.radius5)) {
                    radiusO = [NSNumber numberWithInt:self.radius6];
                    radiusI = [NSNumber numberWithInt:self.radius5];
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius6*2.5, self.radius6*2.5);
//                    [self.mapView setShowsUserLocation:YES];
                }
                else if ((dist <= self.radius5) && (dist > self.radius4)) {
                    radiusO = [NSNumber numberWithInt:self.radius5];
                    radiusI = [NSNumber numberWithInt:self.radius4];
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius5*2.5, self.radius5*2.5);
//                    [self.mapView setShowsUserLocation:YES];
                }
                else if ((dist <= self.radius4) && (dist > self.radius3)) {
                    radiusO = [NSNumber numberWithInt:self.radius4];
                    radiusI = [NSNumber numberWithInt:self.radius3];
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius4*2.5, self.radius4*2.5);
//                    [self.mapView setShowsUserLocation:YES];
                }
                else if ((dist <= self.radius3) && (dist > self.radius2)) { //check for beacons
                    radiusO = [NSNumber numberWithInt:self.radius3];
                    radiusI = [NSNumber numberWithInt:self.radius2];
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius3*2.5, self.radius3*2.5);
//                    [self.mapView setShowsUserLocation:YES];
                    
                }
                else if ((dist <= self.radius2) && (dist > self.radius1)) {
                    radiusO = [NSNumber numberWithInt:self.radius2];
                    radiusI = [NSNumber numberWithInt:self.radius1];
                }
                else if (dist <= self.radius1) {
                    radiusO = [NSNumber numberWithInt:self.radius1];
                    radiusI = [NSNumber numberWithInt:0];
                }
                else if ((dist <= self.radius7) && (dist > self.radius6)) {
                    radiusO = [NSNumber numberWithInt:self.radius7];
                    radiusI = [NSNumber numberWithInt:self.radius6];
                }
                
                if ((dist <= self.radius3) && (dist > self.radius2)) { //should this only track between radii 3 and 2, or between 3 and 0?
                    radiusO = [NSNumber numberWithInt:self.radius3];
                    radiusI = [NSNumber numberWithInt:self.radius2];
                    //between radius 2 and 3
                    //search for runner's beacon
                    //if found, notify with primer, switch to beacons in RVC
                    NSLog(@"Inside %d m", self.radius3);
                    self.runner = runnerLocEntry[@"user"]; //pointer to user, not a user
                    [self.runner fetchIfNeeded];
                    NSString *runnerBeacon = [NSString stringWithFormat:@"%@",[self.runner objectForKey:@"beacon"]];
                    NSLog(runnerBeacon);
                    if ([runnerBeacon isEqualToString:@"Mint 1"]) {
                        self.major = 17784;
                        self.minor = 47397;
                    }
                    else if ([runnerBeacon isEqualToString: @"Ice 1"]) {
                        self.major = 51579;
                        self.minor = 48731;
                    }
                    else if ([runnerBeacon isEqualToString: @"CrowdCheer B"]) {
                        self.major = 28548;
                        self.minor = 7152;
                    }
                    else {
                        //do nothing
                    }
                    
                    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                                     major:self.major
                                                                                     minor:self.minor
                                                                                identifier:@"EstimoteSampleRegion"];
                    
                    // start looking for Estimote beacons in region
                    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
                    [self.beaconManager requestWhenInUseAuthorization];
                    [self.beaconManager startMonitoringForRegion:region];
                    [self.beaconManager startRangingBeaconsInRegion:region];
                }

                
                else if ((dist <= [radiusO doubleValue]) && (dist > [radiusI doubleValue])) { //not updating when we cross into different radii
                    //notify
                    //UI update
                    NSLog(@"Entered %@ m", radiusO);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self runnerApproaching:runnerTracked :dist];
                    });
                }
                else {
                    //outside range
                    NSLog(@"Out of range"); //gets stuck here when distance isn't within the now incorrect inner/outer radius
                }
                
                break; //exiting for loop
            }
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }]; //end of find objects in background with block
    //checking if we found runner
}

//updateDistance(runner)
- (void) updateDistance:(NSTimer*)timer {
    NSDictionary *trackESArgs = (NSDictionary *)[timer userInfo];
    PFUser *runnerTracked = [trackESArgs objectForKey:@"runner"];
    
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    //Find any recent location updates from our runner
    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
    [timeQuery whereKey:@"user" equalTo:runnerTracked];
    [timeQuery orderByDescending:@"updatedAt"];
    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *runnerLocations, NSError *error) {
        if (!error) {
            // The find succeeded. The first 100 objects are available
            //loop through all these possibly nearby runners and check distance
            self.runnerDist = [NSMutableArray array];
            self.runnerPath = [NSMutableArray array];
            for (PFObject *runnerLocEntry in runnerLocations) {
                //getting location for a runner object
                PFGeoPoint *point = [runnerLocEntry objectForKey:@"location"];
                //converting location to CLLocation
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
                //storing in location array
                [self.runnerPath addObject: runnerLoc];
                //calculate distance and store in distance array
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; //in meters
                [self.runnerDist addObject:[NSNumber numberWithDouble:dist]];
                if(self.runnerPath.count > 10) {
                    break;
                }
            }
            
            //Add drawing of route line
            [self.mapView removeAnnotations:self.mapView.annotations];
            [self.mapView setShowsUserLocation:YES];
            [self.mapView addAnnotation:self.runnerPath.firstObject];
            [self drawLine];
            
            
            //update distance label
            double dist = [self.runnerDist.firstObject doubleValue];
            int distInt = (int)dist;
            NSLog(@"runnerDist array: %@", self.runnerDist);
            self.rangeLabel.text = [NSString stringWithFormat:@"%@ is %d meters away", [runnerTracked objectForKey:@"name"], distInt]; //UI update - Runner is x meters and y minutes away
        }
    }];
    
}

- (void)drawLine {
    
    // remove polyline if one exists
    //[self.mapView removeOverlay:self.polyline];
    
    // create an array of coordinates
    CLLocationCoordinate2D coordinates[self.runnerPath.count];
    int i = 0;
    for (CLLocation *currentPin in self.runnerPath) {
        coordinates[i] = currentPin.coordinate;
        i++;
    }
    
    // create a polyline with all cooridnates
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coordinates count:self.runnerPath.count];
    [self.mapView addOverlay:polyline];
    self.polyline = polyline;
    
    // create an MKPolylineView and add it to the map view
    self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
    self.lineView.strokeColor = [UIColor blueColor];
    self.lineView.lineWidth = 3;
    
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
    return self.lineView;
}

//runnerApproaching()
- (void) runnerApproaching:(PFUser*)runner :(const double)distance {
    //runner is within 500m
    NSLog(@"runnerApproaching called");
    if (runner != nil) {
        NSLog(@"runner = %@", runner);
        
        self.runner = runner;
        NSString *runnerName = [NSString stringWithFormat:@"%@",[self.runner objectForKey:@"name"]];
        NSString *runnerObjId = [self.runner valueForKeyPath:@"objectId"];
        self.runnerObjId = runnerObjId;
        
        int dist = (int)distance;
        NSString* distString = [NSString stringWithFormat:@"%d", dist];
        NSString *alertMess =  [runnerName stringByAppendingFormat:@" is %dm away!", dist];
        NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", runnerName, @"name", distString, @"distance", @"approaching", @"runnerStatus", nil];
        NSLog(@"runnerDict: %@", runnerDict);
        
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
        }
        else {
//            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            NSLog(@"about to display cheerAlert");
//            [cheerAlert show];
        }
        
        [self.isCheckingRunners invalidate];
        NSLog(@"invalidated isCheckingRunners");
        
        //setting inner/outer radius and corresponding interval for isTrackingRunner based on current distance
        NSNumber *radiusOuter;
        NSNumber *radiusInner;
        NSNumber *interval;
//        dist = 75.00;
        if ((dist <= self.radius6) && (dist > self.radius5)) { //distance isn't live here, it's being fed into runnerApproaching from trackEachSecond
            radiusOuter = [NSNumber numberWithInt:self.radius6];
            radiusInner = [NSNumber numberWithInt:self.radius5];
            interval = [NSNumber numberWithDouble:30.0]; //10
        }
        else if ((dist <= self.radius5) && (dist > self.radius4)) {
            radiusOuter = [NSNumber numberWithInt:self.radius5];
            radiusInner = [NSNumber numberWithInt:self.radius4];
            interval = [NSNumber numberWithDouble:30.0]; //5
        }
        else if ((dist <= self.radius4) && (dist > self.radius3)) {
            radiusOuter = [NSNumber numberWithInt:self.radius4];
            radiusInner = [NSNumber numberWithInt:self.radius3];
            interval = [NSNumber numberWithDouble:30.0]; //3
        }
        else if ((dist <= self.radius3) && (dist > self.radius2)) { //check for beacons
            radiusOuter = [NSNumber numberWithInt:self.radius3];
            radiusInner = [NSNumber numberWithInt:self.radius2];
            interval = [NSNumber numberWithDouble:3.0]; //5 or 3
        }
        else if ((dist <= self.radius2) && (dist > self.radius1)) {
            radiusOuter = [NSNumber numberWithInt:self.radius2];
            radiusInner = [NSNumber numberWithInt:self.radius1];
            interval = [NSNumber numberWithDouble:2.0]; //1
        }
        else if (dist <= self.radius1) {
            radiusOuter = [NSNumber numberWithInt:self.radius1];
            radiusInner = [NSNumber numberWithInt:0];
            interval = [NSNumber numberWithDouble:0.5]; //1
        }
        else if ((dist <= self.radius7) && (dist > self.radius6)) {
            radiusOuter = [NSNumber numberWithInt:self.radius7];
            radiusInner = [NSNumber numberWithInt:self.radius6];
            interval = [NSNumber numberWithDouble:30.0]; //15
        }
       
        
        NSDictionary *trackESArgs = [NSDictionary dictionaryWithObjectsAndKeys:radiusOuter, @"radiusOuter", radiusInner, @"radiusInner", runner, @"runner", nil];
        [self.isTrackingRunner invalidate];
        [self.isUpdatingDistance invalidate];
        NSLog(@"starting isTrackingRunner with radiusInner: %@ and radiusOuter: %@", radiusInner, radiusOuter);
        self.isTrackingRunner = [NSTimer scheduledTimerWithTimeInterval:([interval doubleValue]) target:self
                                                               selector:@selector(trackEachSecond:) userInfo:trackESArgs repeats:YES];
        self.isUpdatingDistance = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self
                                                                             selector:@selector(updateDistance:) userInfo:trackESArgs repeats:YES];
        
    }
    
    else {
        NSLog(@"Runner was nil");
    }
}

- (void) foundRunner:(PFUser*)runner :(const double)distance{
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
        int dist = (int)distance;
        NSString* distString = [NSString stringWithFormat:@"%d", dist];
        NSString *alertMess =  [runnerName stringByAppendingFormat:@" is coming, get ready to cheer!"];
        NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", @"here", @"runnerStatus", runnerName, @"name", distString, @"distance", nil]; //need distance here
        
        //saving parse data for when cheerer receives notification and for which runner
        PFObject *cheererNotification = [PFObject objectWithClassName:@"cheererWasNotified"];
        [cheererNotification setObject:self.runner forKey:@"runner"];
        [cheererNotification setObject:self.cheerer forKey:@"cheerer"];
        NSLog(@"self.runner is %@", self.runner);
        [cheererNotification saveInBackground];
        NSLog(@"cheererNotification is %@", cheererNotification);
        
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        NSLog(@"application state is %d", state);
        self.cheerButton.hidden = NO;
        if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
        {
            // This code sends notification to didFinishLaunchingWithOptions in AppDelegate.m
            // userInfo can include the dictionary above called runnerDict
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated"
                                                                object:self
                                                              userInfo:runnerDict];
            
            NSLog(@" notifying about %@ from background", self.runnerObjId);
        } else {
//            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            NSLog(@"about to display cheerAlert");
//            [cheerAlert show];
//            //                    self.runnerObjId = runnerObjId;
//            //                    NSLog(@"%@ in main thread", runnerObjId);
            
        }
        
        [self.isTrackingRunner invalidate];
        NSLog(@"invalidated isTrackingRunner");
//        self.didRunnerExit = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
//                                                            selector:@selector(checkRunnerLocation:) userInfo:runner repeats:YES];
        
    } else {
        NSLog(@"Runner was nil");
    }
    
}

-(IBAction)cheerPressed:(id)sender {
    
//    PFObject *startCheering = [PFObject objectWithClassName:@"startCheeringTime"];
//    NSLog(self.runner, [PFUser currentUser]);
//    startCheering[@"runnerMotivated"] = self.runner; //runner is null here
//    startCheering[@"cheerer"] = [PFUser currentUser];
//    [startCheering saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            NSLog(@"saved Cheering Time");
//        } else {
//            // There was a problem, check error.description
//        }
//    }];
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
                    if (dist > self.radius2){
                        NSLog(@"runner exited %f!", self.radius2);
                        [self.didRunnerExit invalidate];
                       // [self.hapticTimer invalidate];
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
        NSNumber *distance = [NSNumber numberWithDouble: closestBeacon.accuracy];
        NSLog(@"beacon distance: %f", closestBeacon.accuracy);
        //notify with primer
        PFQuery *query = [PFUser query];
        PFUser *runner = (PFUser *)[query getObjectWithId:self.runnerObjId];
        NSLog(@"sending primer for runner %@", runner);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self foundRunner:runner :[distance doubleValue]];
        });
//        [self.isTrackingRunner invalidate];
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
    self.locationManager.distanceFilter = 1; // meters
    
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    
    //setting up mapview
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius7*2.5, self.radius7*2.5);
    [self.mapView setShowsUserLocation:YES];
    [self.mapView setDelegate:self];
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
    [cheerLocation setObject:self.cheerer forKey:@"user"];
    NSLog(@"CheererLocation is %@", loc);
    
    [cheerLocation saveInBackground];
    /**
     if (!checkQueue){
     checkQueue = dispatch_queue_create("com.crowdcheer.runnerCheck", NULL);
     }
     */
    
}

- (void)resizeMap {
//zoom map to include runner route
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
    
    NSLog(@"prepareForSegue: %@", segue.identifier);
    
    if ([segue.identifier isEqualToString:@"relationshipSegue"]) {
        [segue.destinationViewController setRunnerObjId:self.runnerObjId];
        NSLog(@"==============Segueing with %@===============", self.runnerObjId);
    }
    else {
         NSLog(@"==============Segue ERROR===============");
    }
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