//
//  RelationshipViewController.m
//  CrowdCheer
//
//  Created by Christina Kim on 3/3/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "RelationshipViewController.h"
#import "MotivatorViewController.h"
#import "NewRunViewController.h"
#import "DetailViewController.h"
#import "Run.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>
#import "MathController.h"
#import "Location.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <EstimoteSDK/EstimoteSDK.h>


@interface RelationshipViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, ESTBeaconManagerDelegate, MKMapViewDelegate, AVAudioRecorderDelegate>

@property (nonatomic, strong) Run *run;

@property (nonatomic, strong) NSTimer *hapticTimer;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSTimer *isTrackingRunner;
@property (nonatomic, strong) NSTimer *isUpdatingDistance;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property int major;
@property int minor;
@property int radius1;
@property int radius2;
@property int radius3;
@property int radius4;
@property int radius5;
@property int radius6;
@property int radius7;
@property NSString* name;
@property (weak, nonatomic) PFUser *cheerer;
@property (weak, nonatomic) PFUser *runner;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *bibLabel;
@property (nonatomic, weak) IBOutlet UILabel *commonalityLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *runnerDist;
@property (nonatomic, readwrite) CLLocationAccuracy beaconDist;
@property (nonatomic, readwrite) MKPolyline *polyline; //your line
@property (nonatomic, readwrite) MKPolylineView *lineView; //your line view
@property (nonatomic, strong) NSMutableArray *runnerPath;
@property (nonatomic, strong)AVAudioRecorder *recorder;
@property (nonatomic, readwrite) NSString *fileName;


@end


@implementation RelationshipViewController

- (void)viewDidLoad {
    
    //
    //load runner info
    //
    if (self.runnerObjId == NULL) { //if runner wasn't set via button press, check local notif dictionary for a value
        self.runnerObjId = [self.userInfo objectForKey:@"user"];
    }
    PFQuery *query = [PFUser query];
    self.runner = (PFUser *)[query getObjectWithId:self.runnerObjId];
    
    PFFile *userImageFile = self.runner[@"profilePic"];
    [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *profilePic = [UIImage imageWithData:imageData];
            self.imageView.image = profilePic;
        }
    }];
    self.name = self.runner[@"name"];
    NSString *bibNumber = self.runner[@"bibNumber"];
    NSString *commonality = self.runner[@"display commonality here"];
    
    self.nameLabel.text = [NSString stringWithFormat:@"%@!", self.name];
    self.bibLabel.text = [NSString stringWithFormat:@" Bib #: %@", bibNumber];
    self.commonalityLabel.text = [NSString stringWithFormat:@"You are both %@!", commonality];
    

    NSString *runnerBeacon = self.runner[@"beacon"];
    if ([runnerBeacon isEqualToString:@"Mint 1"]) {
        self.major = 17784;
        self.minor = 47397;
    }
    else if ([runnerBeacon isEqualToString:@"Ice 1"]) {
        self.major = 51579;
        self.minor = 48731;
    }
    else if ([runnerBeacon isEqualToString:@"CrowdCheer B"]) {
        self.major = 28548;
        self.minor = 7152;
    }
    else {
        //do nothing
    }

    //
    //setting up mapview
    //
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    [self.locationManager startUpdatingLocation];
    
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 200, 200);
    [self.mapView setShowsUserLocation:YES];
    NSDictionary *trackESArgs = [NSDictionary dictionaryWithObjectsAndKeys:self.runner, @"runner", nil];
    self.isUpdatingDistance = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                             selector:@selector(updateDistance:) userInfo:trackESArgs repeats:YES];
    
    //radius in meters, smaller index = closer to runner
    self.radius1 = 10; //10
    self.radius2 = 50; //50
    self.radius3 = 100;//100
    self.radius4 = 200;//200
    self.radius5 = 300;//300
    self.radius6 = 400;//400
    self.radius7 = 500;//500
    
    double dist = [self.runnerDist.firstObject doubleValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self runnerApproaching:self.runner :dist]; //notify
    });
   
    //
    //preparing for recording
    //
    // Set the audio file
    self.cheerer = [PFUser currentUser];
    NSString *cheererName = self.cheerer.username;
    self.fileName = (@"cheer_%@_for_%@.m4a", cheererName, self.name);
    NSLog(@"file name: %@, cheerer: %@, runner: %@", self.fileName, cheererName, self.name); //runner name is null when beacon not found in MVC?
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               self.fileName,
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    [session setActive:YES error:nil];
    
//    // Start recording
//    [self.recorder record];

    
    //
    //setting up beacon listener
    //
    self.beaconDist = -1;
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                     major:self.major
                                                                     minor:self.minor
                                                                identifier:@"EstimoteSampleRegion"];

    [self.beaconManager requestWhenInUseAuthorization];
    [self.beaconManager startMonitoringForRegion:region];
    [self.beaconManager startRangingBeaconsInRegion:region];
    
    [super viewDidLoad];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.isTrackingRunner invalidate];
    [self.isUpdatingDistance invalidate];
    [self.hapticTimer invalidate];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"RelationshipViewController.viewWillAppear()");

    self.commonalityLabel.hidden = YES;
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
        NSLog(@"application state is %ld", (long)state);
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
        self.isUpdatingDistance = [NSTimer scheduledTimerWithTimeInterval:(3.0) target:self
                                                                 selector:@selector(updateDistance:) userInfo:trackESArgs repeats:YES];
        
    }
    
    else {
        NSLog(@"Runner was nil");
    }
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
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius6*2.1, self.radius6*2.1);
                    //                    [self.mapView setShowsUserLocation:YES];
                }
                else if ((dist <= self.radius5) && (dist > self.radius4)) {
                    radiusO = [NSNumber numberWithInt:self.radius5];
                    radiusI = [NSNumber numberWithInt:self.radius4];
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius5*2.1, self.radius5*2.1);
                    //                    [self.mapView setShowsUserLocation:YES];
                }
                else if ((dist <= self.radius4) && (dist > self.radius3)) {
                    radiusO = [NSNumber numberWithInt:self.radius4];
                    radiusI = [NSNumber numberWithInt:self.radius3];
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius4*2.1, self.radius4*2.1);
                    //                    [self.mapView setShowsUserLocation:YES];
                }
                else if ((dist <= self.radius3) && (dist > self.radius2)) { //check for beacons
                    radiusO = [NSNumber numberWithInt:self.radius3];
                    radiusI = [NSNumber numberWithInt:self.radius2];
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius3*2.1, self.radius3*2.1);
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


- (void)setVibrations{
    [self.recorder stop];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    NSLog(@"vibrate");
}

- (void)setRunnerObjId:(NSString *)runnerObjId {
    _runnerObjId = runnerObjId;
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
        NSLog(@"beacon distance: %f", closestBeacon.accuracy);
        self.beaconDist = closestBeacon.accuracy;
        double dist = [self.runnerDist.firstObject doubleValue];
        int beaconDistInt = (int)self.beaconDist;
        
//         calculate and set new y position
        
        //vibrate by beacon distance
        if (self.beaconDist > 70) {
            [self.hapticTimer invalidate];
        }
        else if (self.beaconDist > 50 && self.beaconDist <= 60) {
            [self.hapticTimer invalidate];
            self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(3) target:self
                                                              selector:@selector(setVibrations) userInfo:nil repeats:YES];
        }
        else if (self.beaconDist > 40 && self.beaconDist <= 50) {
            [self.hapticTimer invalidate];
            self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(2) target:self
                                                              selector:@selector(setVibrations) userInfo:nil repeats:YES];
            
        }
        else if (self.beaconDist > 30 && self.beaconDist <= 40) {
            [self.hapticTimer invalidate];
            self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
                                                              selector:@selector(setVibrations) userInfo:nil repeats:YES];
            
        }
        else if (self.beaconDist > -1 && self.beaconDist <= 30) {
            // Start recording
            [self.hapticTimer invalidate];
//            self.rangeLabel.text = [NSString stringWithFormat:@"%.02f m away - CHEER NOW!", self.beaconDist];
            [self.recorder record];
        }
        
        
//        switch (closestBeacon.proximity)
//        {
//            case CLProximityUnknown: {
//               
//                [self.hapticTimer invalidate];
//            }
//                break;
//            case CLProximityImmediate:
////                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is HERE! (0-2m)", self.name];
//                [self.hapticTimer invalidate];
//                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
//                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//                break;
//            case CLProximityNear:
////                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is HERE! (0-2m)", self.name];
//                [self.hapticTimer invalidate];
//                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
//                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//                break;
//            case CLProximityFar:
////                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is NEAR! (2-70m)", self.name];
//                [self.hapticTimer invalidate];
//                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(3.0) target:self
//                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
//                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//                break;
//                
//            default:
//                break;
//        }
    }
    
    else {
        double dist = [self.runnerDist.firstObject doubleValue];
        //vibrate by loc distance
        if (dist > 70) {
            [self.hapticTimer invalidate];
        }
        else if (dist > 50 && dist <= 60) {
            [self.hapticTimer invalidate];
            self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(3) target:self
                                                              selector:@selector(setVibrations) userInfo:nil repeats:YES];
        }
        else if (dist > 40 && dist <= 50) {
            [self.hapticTimer invalidate];
            self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(2) target:self
                                                              selector:@selector(setVibrations) userInfo:nil repeats:YES];
            
        }
        else if (dist > 30 && dist <= 40) {
            [self.hapticTimer invalidate];
            self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
                                                              selector:@selector(setVibrations) userInfo:nil repeats:YES];
            
        }
        else if (dist > -1 && dist <= 30) {
            // Start recording
            [self.hapticTimer invalidate];
//            self.rangeLabel.text = [NSString stringWithFormat:@"%.02f m away - CHEER NOW!", dist];
            [self.recorder record];
        }
    }
    
    
    
    double dist = [self.runnerDist.firstObject doubleValue];
    double distPrev = [self.runnerDist[9] doubleValue];
    NSLog(@"dist %f, distPrev %f", dist, distPrev);
    if (dist > distPrev) {
        NSLog(@"distance increasing");
        if (dist > 30 || self.beaconDist > 30) {
            NSLog(@"calling runnerExits");
            [self runnerExits :self.runner];
        }
    }
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
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locationManager.location]; //in meters
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
            if (self.beaconDist == -1) {
                NSLog(@"runnerDist array: %@", self.runnerDist);
                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is %d meters away", [runnerTracked objectForKey:@"name"], distInt]; //UI update - Runner is x meters and y minutes away
            }
            else if (self.beaconDist > 30) {
                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is %.02f meters away", [runnerTracked objectForKey:@"name"], self.beaconDist]; //UI update - Runner is x meters and y minutes away
            }
        }
    }];
    
    
}

- (void) runnerExits: (PFUser*)runner {
    //if runner exits 30m radius, stop the recording, stop the beacon manager, invalidate timers, segue back to runner search
    
    double dist = [self.runnerDist.firstObject doubleValue];
    int distInt = (int)dist;
    self.runner = runner;
    
    if (dist > 30 || self.beaconDist > 30) {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                         major:self.major
                                                                         minor:self.minor
                                                                    identifier:@"EstimoteSampleRegion"];
        
        [self.beaconManager stopMonitoringForRegion:region];
        [self.beaconManager stopRangingBeaconsInRegion:region];
        [self.isUpdatingDistance invalidate];
        [self.hapticTimer invalidate];
        
        self.rangeLabel.text = [NSString stringWithFormat:@"Thanks for cheering! Hit BACK to cheer for more runners."];
        //stop recording and store to Parse
        [self.recorder stop];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
        NSData *recorderData = [NSData dataWithContentsOfURL:self.recorder.url];
        PFObject *startCheering = [PFObject objectWithClassName:@"startCheeringTime"];
        NSLog(@"file name inside beacon mgr: %@", self.fileName);
        PFFile *recorderFile = [PFFile fileWithName:self.fileName data:recorderData];
        NSLog(@"recorderFile to store to Parse: %@", recorderFile);
        startCheering[@"audio"] = recorderFile;
        NSLog(@"runner %@, cheerer %@", self.runner, self.cheerer);
        [startCheering setObject:self.runner forKey:@"runner"];
        [startCheering setObject:self.cheerer forKey:@"cheerer"];
        
        [startCheering saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"saved Cheering Time");
            } else {
                // There was a problem, check error.description
            }
        }];
        
        NSLog(@"Runner exits region, returning to MVC");
        //return to watching screen
        //                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        //                RelationshipViewController *rsvc = (RelationshipViewController *)[sb instantiateViewControllerWithIdentifier:@"relationshipViewController"];
        [self.navigationController popViewControllerAnimated:YES];

    }
}


- (void)drawLine {
    
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



@end
