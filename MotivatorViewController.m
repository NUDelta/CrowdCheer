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

@interface MotivatorViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@end

@implementation MotivatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                selector:@selector(eachSecond) userInfo:nil repeats:YES];
    [self startLocationUpdates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)eachSecond
{
    PFGeoPoint *loc  = [PFGeoPoint geoPointWithLocation:self.locations.lastObject];
    PFUser *thisUser = [PFUser currentUser];
    
    PFObject *cheerLocation = [PFObject objectWithClassName:@"CheerLocation"];
    [cheerLocation setObject:[[NSDate alloc] init] forKey:@"time"];
    [cheerLocation setObject:loc forKey:@"location"];
    [cheerLocation setObject:thisUser forKey:@"user"];
    
    [cheerLocation saveInBackground];
    [self checkForRunners];
}

- (void)checkForRunners
{
    //query for runners nearby
    PFQuery *query = [PFQuery queryWithClassName:@"RunnerLocation"];
    [query whereKey:@"location" nearGeoPoint:[PFGeoPoint geoPointWithLocation:self.locations.lastObject]withinMiles:.1];
    NSArray *placeObjects = [query findObjects];
    
    //take first nearby runner
    PFUser *runnerToCheer = placeObjects.firstObject[@"user"];
    NSString *runnerName = runnerToCheer[@"username"];
    NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
    // query for runner cheerer similarity
    UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:@"Someone needs a cheer!" message:alertMess delegate:nil cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];
    
    [cheerAlert show];
    
    //if runner is nearby and new distance is less than old distance
    // notify cheerer
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
            
            [self.locations addObject:newLocation];
        }
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
