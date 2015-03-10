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

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *bibLabel;
@property (nonatomic, weak) IBOutlet UILabel *commonalityLabel;

@property (weak, nonatomic) PFUser *runnerToCheer;
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
    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];
    NSArray *possibleNearbyRunners = [timeQuery findObjects];
    
    //get locations for all these possibly nearby runners and check distance
    for (PFObject *possible in possibleNearbyRunners) {
        PFGeoPoint *point = [possible objectForKey:@"location"];

        CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
        CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations.lastObject]; //in meters
        if (dist < 200){
            PFObject *user = possible[@"user"];
            [user fetchIfNeeded];
            NSString *runnerName = user[@"name"];
            NSLog(@"%@", possible.objectId);
            NSString *alertMess =  [runnerName stringByAppendingFormat:@" needs your help!"];
            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:alertMess delegate:nil cancelButtonTitle:@"Cheer!" otherButtonTitles:nil, nil];

            UIImage *profilePic = user[@"profilePic"];
            self.imageView.image = profilePic;
            _nameLabel = user[@"name"];
            _bibLabel = user[@"bibNumber"];
            _commonalityLabel = @"display commonality here";
            
            [self.timer invalidate];
            [cheerAlert show];
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
