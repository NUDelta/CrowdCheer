//
//  RelationshipViewController.m
//  CrowdCheer
//
//  Created by Christina Kim on 3/3/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "RelationshipViewController.h"
#import "NewRunViewController.h"
#import "DetailViewController.h"
#import "Run.h"
#import <CoreLocation/CoreLocation.h>
#import "MathController.h"
#import "Location.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <EstimoteSDK/EstimoteSDK.h>


@interface RelationshipViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, ESTBeaconManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) Run *run;

@property (nonatomic, strong) NSTimer *hapticTimer;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSTimer *isUpdatingDistance;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property int major;
@property int minor;
@property NSString* name;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *bibLabel;
@property (nonatomic, weak) IBOutlet UILabel *commonalityLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *runnerDist;

@end


@implementation RelationshipViewController

- (void)viewDidLoad {
    //load runner info
    NSString *userObjectID = [self.userInfo objectForKey:@"user"];
    NSLog(@"User ID passed to RVC is %@""", userObjectID);
    PFQuery *query = [PFUser query];
    PFUser *user = (PFUser *)[query getObjectWithId:userObjectID];
    NSLog(@"User passed to RVC is %@", user);
    
   // NSString *runnerBeacon = [NSString stringWithFormat:@"%@",[self.userInfo objectForKey:@"beacon"]];
    NSString *runnerBeacon = user[@"beacon"];
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
    //setting up mapview
    NSDictionary *trackESArgs = [NSDictionary dictionaryWithObjectsAndKeys:user, @"runner", nil];
    self.isUpdatingDistance = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                             selector:@selector(updateDistance:) userInfo:trackESArgs repeats:YES];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    [self.locationManager startUpdatingLocation];
    
    CLLocation *location = [self.locationManager location];
    
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 200, 200);
    
    [self.mapView setShowsUserLocation:YES];
    
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                     major:self.major
                                                                     minor:self.minor
                                                                identifier:@"EstimoteSampleRegion"];
    // start looking for Estimote beacons in region
    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
    
    //location
    [self.beaconManager requestWhenInUseAuthorization];
    [self.beaconManager startMonitoringForRegion:region];
    [self.beaconManager startRangingBeaconsInRegion:region];
    
    [super viewDidLoad];
    //if local notif
    if (!self.fromAlert) {
//        NSString *userObjectID = [self.userInfo objectForKey:@"user"];
//        NSLog(@"User ID passed to RVC is %@""", userObjectID);
//        PFQuery *query = [PFUser query];
//        PFUser *user = (PFUser *)[query getObjectWithId:userObjectID];
//        NSLog(@"User passed to RVC is %@", user);
        //Once we have the Runner's account as user, we can use this code to pull data for the motivator:
        if(!user) {
            NSLog(@"ERROR: No user object passed.");
        }
        else {
            PFFile *userImageFile = user[@"profilePic"];
            [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                if (!error) {
                    UIImage *profilePic = [UIImage imageWithData:imageData];
                    self.imageView.image = profilePic;
                }
            }];
            
            
            self.name = user[@"name"];
            NSString *bibNumber = user[@"bibNumber"];
            NSString *commonality = user[@"display commonality here"];
            NSString *beacon = user[@"beacon"];
            NSLog(self.name);
            
            self.nameLabel.text = [NSString stringWithFormat:@"%@!", self.name];
            self.bibLabel.text = [NSString stringWithFormat:@" Bib #: %@", bibNumber];
            self.commonalityLabel.text = [NSString stringWithFormat:@"You are both %@!", commonality];
            
            PFObject *startCheering = [PFObject objectWithClassName:@"startCheeringTime"];
            startCheering[@"runnerMotivated"] = user;
            startCheering[@"cheerer"] = [PFUser currentUser];
            [startCheering saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    // The object has been saved.
                } else {
                    // There was a problem, check error.description
                }
            }];
        }
    }
    
    //if alert
    else {
//        NSString *userObjectID = [self.userInfo objectForKey:@"user"];
//        NSLog(@"User ID passed to RVC is %@""", self.runnerObjId);
//        PFQuery *query = [PFUser query];
//        PFUser *user = (PFUser *)[query getObjectWithId:self.runnerObjId];
//        NSLog(@"User passed to RVC is %@", user);
        //Once we have the Runner's account as user, we can use this code to pull data for the motivator:
        if(!user) {
            NSLog(@"ERROR: No user object passed.");
        } else {
            PFFile *userImageFile = user[@"profilePic"];
            [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                if (!error) {
                    UIImage *profilePic = [UIImage imageWithData:imageData];
                    self.imageView.image = profilePic;
                }
            }];
            
            NSString *name = user[@"name"];
            NSString *bibNumber = user[@"bibNumber"];
            NSString *commonality = user[@"display commonality here"];
            NSLog(self.name);
            
            self.nameLabel.text = [NSString stringWithFormat:@"%@!", self.name];
            self.bibLabel.text = [NSString stringWithFormat:@" Bib #: %@", bibNumber];
            self.commonalityLabel.text = [NSString stringWithFormat:@"You are both %@!", commonality];
            
            PFObject *startCheering = [PFObject objectWithClassName:@"startCheeringTime"];
            startCheering[@"runnerMotivated"] = user;
            startCheering[@"cheerer"] = [PFUser currentUser];
            [startCheering saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    // The object has been saved.
                } else {
                    // There was a problem, check error.description
                }
            }];        }
    }
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
        switch (closestBeacon.proximity)
        {
            case CLProximityUnknown:
                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is out of range!",self.name];
                break;
            case CLProximityImmediate:
                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is HERE! (0-2m)", self.name];
                [self.hapticTimer invalidate];
                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
                break;
            case CLProximityNear:
                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is HERE! (0-2m)", self.name];
                [self.hapticTimer invalidate];
                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5) target:self
                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
                break;
            case CLProximityFar:
                self.rangeLabel.text = [NSString stringWithFormat:@"%@ is NEAR! (2-70m)", self.name];
                [self.hapticTimer invalidate];
                self.hapticTimer = [NSTimer scheduledTimerWithTimeInterval:(3.0) target:self
                                                                  selector:@selector(setVibrations) userInfo:nil repeats:YES];
                break;
                
            default:
                break;
        }
    }
}

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
            NSMutableArray *runnerPath = [NSMutableArray array];
            self.runnerDist = [NSMutableArray array];
            for (PFObject *runnerLocEntry in runnerLocations) {
                //getting location for a runner object
                PFGeoPoint *point = [runnerLocEntry objectForKey:@"location"];
                //converting location to CLLocation and CLLocationCoordinate2D
                CLLocationCoordinate2D runnerCoor = CLLocationCoordinate2DMake(point.latitude, point.longitude);
                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
                //storing in coordinate and location array
                [runnerPath addObject: runnerLoc];
                //calculate distance and store in distance array
                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; //in meters
                [self.runnerDist addObject:[NSNumber numberWithDouble:dist]];
                
            }
            
            //Add drawing of route line
            CLLocationCoordinate2D coordinates[[runnerPath count]];
            
            
            for (CLLocation *loc in runnerPath)
            {
                int i = 0;
                coordinates[i] = CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude);
                i++;
            }
            
            MKPolyline *route = [MKPolyline polylineWithCoordinates: coordinates count:runnerPath.count];
            [self.mapView addOverlay:route];
            [self.mapView addAnnotations:runnerPath];
            MKPolylineRenderer *pr = (MKPolylineRenderer *)[self.mapView rendererForOverlay:route];
            //            [pr invalidatePath];
            
            
            
            //update distance label
            double dist = [self.runnerDist.firstObject doubleValue];
            int distInt = (int)dist;
            NSLog(@"runnerDist array: %@", self.runnerDist);
            //            NSLog(@"runnerPath array: %@", coordinates[0]);
            self.rangeLabel.text = [NSString stringWithFormat:@"%@ is %d meters away", [runnerTracked objectForKey:@"name"], distInt]; //UI update - Runner is x meters and y minutes away
        }
    }];
    
}

- (MKPolylineRenderer*)mapView:(MKMapView*)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *pr = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        pr.strokeColor = [UIColor blueColor];
        pr.lineWidth = 5;
        return pr;
    }
    
    return nil;
}



@end
