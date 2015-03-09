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
@end

@implementation MotivatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"MotivatorViewController.viewDidLoad()");
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
    PFQuery *query = [PFQuery queryWithClassName:@"RunnerLocation"];
    //then check for those runners who have updated recently and are "nearby"
    [query whereKey:@"location" nearGeoPoint:[PFGeoPoint geoPointWithLocation:self.locations.lastObject]withinKilometers:.2];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            unsigned long numRunners = (unsigned long)objects.count;
            NSLog(@"Successfully retrieved %lu runners.", numRunners);
            if (numRunners > 0){
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *runnerName = @"MeatMan";
                    NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
                    // query for runner cheerer similarity
                    UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:@"Someone needs a cheer!" message:alertMess delegate:nil cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];
                    [self.timer invalidate];
                    [cheerAlert show];
                    
                });
            }
            
            /**
            NSLog(@"Successfully retrieved %d scores.", objects.count);
            // Do something with the found objects
            for (PFObject *object in objects) {
                NSLog(@"%@", object.objectId);
                PFUser *runnerToCheer = object[@"user"];
                NSString *runnerName = runnerToCheer[@"username"];
                NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
                NSLog(runnerName);
            }
             */
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
    //NSArray *placeObjects = [query findObjects];
    
    
    /**
    //take first nearby runner
    PFUser *runnerToCheer = placeObjects.firstObject[@"user"];
    NSString *runnerName = runnerToCheer[@"username"];
    NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
    // query for runner cheerer similarity
    UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:@"Someone needs a cheer!" message:alertMess delegate:nil cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];
    
    [cheerAlert show];
    
    //if runner is nearby and new distance is less than old distance
    // notify cheerer
    */
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
