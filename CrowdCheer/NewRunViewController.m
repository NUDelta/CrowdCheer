//
//  NewRunViewController.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/9/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "NewRunViewController.h"
#import "DetailViewController.h"
#import "Run.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MathController.h"
#import "Location.h"
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>

static NSString * const detailSegueName = @"RunDetails";

@interface NewRunViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate, MKMapViewDelegate>

@property (nonatomic, strong) Run *run;

@property int seconds;
@property float distance;
@property NSString *pace;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSTimer *timer;


@property (nonatomic, weak) IBOutlet UILabel *instruction1Label;
@property (nonatomic, weak) IBOutlet UILabel *instruction2Label;
@property (nonatomic, weak) IBOutlet UILabel *congratsLabel;




@property (nonatomic, weak) IBOutlet UILabel *promptLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *distLabel;
@property (nonatomic, weak) IBOutlet UILabel *paceLabel;

@property (nonatomic, weak) IBOutlet UIButton *startButton;
@property (nonatomic, weak) IBOutlet UIButton *stopButton;

@property (nonatomic, weak) IBOutlet UIButton *prepButton;
@property (weak, nonatomic) IBOutlet UITextField *targetPace;
@property (weak, nonatomic) IBOutlet UITextField *raceTimeGoal;
@property (weak, nonatomic) IBOutlet UITextField *bibNumber;

@property (strong, nonatomic) IBOutlet UIPickerView *beaconPicker;
@property (strong, nonatomic) NSArray *beaconArray;
@property (weak, nonatomic) IBOutlet UITextField *beaconName;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, readwrite) MKPolyline *polyline; //your line
@property (nonatomic, readwrite) MKPolylineView *lineView; //your line view
@property (nonatomic, strong) NSMutableArray *runnerPath;

@end


@implementation NewRunViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"NewRunViewController.viewDidLoad()");
    
    
    //If any profile data is saved, display it
    
    PFUser *user = [PFUser currentUser];
    
    NSString *targetPace = user[@"targetPace"];
    NSString *raceTimeGoal = user[@"raceTimeGoal"];
    NSString *bibNumber = user[@"bibNumber"];
    
    self.targetPace.text = targetPace;
    self.raceTimeGoal.text = raceTimeGoal;
    self.bibNumber.text = bibNumber;

    [self.targetPace addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.raceTimeGoal addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.bibNumber addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    [self.prepButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    if ([user objectForKey:@"targetPace"]== nil){
        self.prepButton.enabled = NO;
    }
    else if ([user objectForKey:@"raceTimeGoal"]==nil) {
        self.prepButton.enabled = NO;
    }
    else if ([user objectForKey:@"bibNumber"]==nil) {
        self.prepButton.enabled = NO;
    }
    else if ([user objectForKey:@"beacon"]==nil) {
        self.prepButton.enabled = NO;
    }
    else {
        self.prepButton.enabled = YES;
    }
    
    self.beaconArray  = [[NSArray alloc] initWithObjects:@"Mint 1", @"Ice 1", @"CrowdCheer B", nil];
    self.beaconPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    [self attachPickerToTextField:self.beaconName :self.beaconPicker];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"NewRunViewController.viewWillAppear()");
    [self.view endEditing:YES];

    self.startButton.hidden = NO;
    self.promptLabel.hidden = NO;
    
    self.timeLabel.text = @"";
    self.timeLabel.hidden = YES;
    self.distLabel.hidden = YES;
    self.paceLabel.hidden = YES;
    self.stopButton.hidden = YES;
    self.congratsLabel.hidden = YES;
    self.mapView.hidden = YES;
    
    

}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.beaconPicker){
        return self.beaconArray.count;
    }
    
    return 0;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row   forComponent:(NSInteger)component
{
    if (pickerView == self.beaconPicker){
        return [self.beaconArray objectAtIndex:row];
    }
    
    return @"???";
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row   inComponent:(NSInteger)component
{
    PFUser *currentUser = [PFUser currentUser];
    
    if (pickerView == self.beaconPicker){
        self.beaconName.text = [self.beaconArray objectAtIndex:row];
        currentUser[@"beacon"] = self.beaconName.text;
    }

    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"beacon saved!");
        } else {
            NSLog(@"beacon not saved =(");
        }
    }];
}

- (void)attachPickerToTextField: (UITextField*) textField :(UIPickerView*) picker{
    picker.delegate = self;
    picker.dataSource = self;
    
    textField.delegate = self;
    textField.inputView = picker;
    
}

-(void)textFieldDidChange :(UITextField *)textField{
    //save profile info to Parse
    PFUser *currentUser = [PFUser currentUser];
    if (textField == self.targetPace){
        currentUser[@"targetPace"] = self.targetPace.text;
    }
    
    else if (textField == self.raceTimeGoal){
        currentUser[@"raceTimeGoal"] = self.raceTimeGoal.text;
    }
    
    else if (textField == self.bibNumber){
        currentUser[@"bibNumber"] = self.bibNumber.text;
    }
    
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
    
    if (([currentUser objectForKey:@"targetPace"]== nil) ||
        ([currentUser objectForKey:@"raceTimeGoal"]==nil) ||
        ([currentUser objectForKey:@"bibNumber"]==nil) )
    {
        self.prepButton.enabled = NO;
    }
    else {
        self.prepButton.enabled = YES;
    }
}



-(IBAction)prepPressed:(id)sender
{

//    PFUser *currentUser = [PFUser currentUser];
//    currentUser[@"targetPace"] = self.targetPace.text;
//    currentUser[@"raceTimeGoal"] = self.raceTimeGoal.text;
//    currentUser[@"bibNumber"] = self.bibNumber.text;
//    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            // The object has been saved.
//        } else {
//            // There was a problem, check error.description
//        }
//    }];
}

-(IBAction)startPressed:(id)sender
{
    
    // hide the start UI
    self.startButton.hidden = YES;
    self.promptLabel.hidden = YES;
    self.congratsLabel.hidden = YES;

    
    // show the running UI
    self.timeLabel.hidden = NO;
    self.distLabel.hidden = NO;
    self.paceLabel.hidden = NO;
    self.stopButton.hidden = NO;
    
    self.seconds = 0;
    self.distance = 0;
    self.locations = [NSMutableArray array];
    self.runnerPath = [NSMutableArray array];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                selector:@selector(eachSecond) userInfo:nil repeats:YES];
    [self startLocationUpdates];
}

- (IBAction)stopPressed:(id)sender
{
    // hide the instructions UI
    self.instruction1Label.hidden = YES;
    self.instruction2Label.hidden = YES;

    // show the congrats label UI
    self.congratsLabel.hidden = NO;
    self.stopButton.hidden = YES;
    
    //load map of race here
    self.mapView.hidden = NO;
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
    [self.mapView setShowsUserLocation:YES];
    [self drawLine];
    
    [self.locationManager stopUpdatingLocation];
    [self.timer invalidate];
    
}

- (void)drawLine {
    
    // remove polyline if one exists
    //[self.mapView removeOverlay:self.polyline];
    
    // create an array of coordinates
    NSLog(@"runnerPath %@", self.runnerPath);
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
     NSLog(@"polyline %@", self.polyline);
    
    // create an MKPolylineView and add it to the map view
    self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
    self.lineView.strokeColor = [UIColor blueColor];
    self.lineView.lineWidth = 5;
    
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
    return self.lineView;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [[segue destinationViewController] setRun:self.run];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.timer invalidate];
}

- (void)eachSecond
{
    NSLog(@"NewRunViewController.eachSecond()");
    PFGeoPoint *loc  = [PFGeoPoint geoPointWithLocation:self.locations.lastObject];
    PFUser *thisUser = [PFUser currentUser];
    
    PFObject *runnerLocation = [PFObject objectWithClassName:@"RunnerLocation"];
    [runnerLocation setObject:[[NSDate alloc] init] forKey:@"time"];
    
    //add pace as key
    self.pace = [MathController stringifyAvgPaceFromDist:self.distance overTime:self.seconds];
    NSNumber *runTime = [NSNumber numberWithInt:self.seconds];
    NSNumber *distance = [NSNumber numberWithFloat:self.distance];
    [runnerLocation setObject:loc forKey:@"location"];
    [runnerLocation setObject:thisUser forKey:@"user"];
    [runnerLocation setObject:self.pace forKey:@"pace"];
    [runnerLocation setObject:distance forKey:@"distance"];
    [runnerLocation setObject:runTime forKey:@"runTime"]; //runnerLocation[@"runtime"]
    
    [runnerLocation saveInBackground];
    
    self.seconds++;
    self.timeLabel.text = [NSString stringWithFormat:@"Time: %@",  [MathController stringifySecondCount:self.seconds usingLongFormat:NO]];
    self.distLabel.text = [NSString stringWithFormat:@"Distance: %@", [MathController stringifyDistance:self.distance]];
    self.paceLabel.text = [NSString stringWithFormat:@"Pace: %@",  self.pace];
    
    [self.runnerPath addObject: self.locationManager.location];
    
//    //Find any recent location updates from our runner
//    PFUser *runner = [PFUser currentUser];
//    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
//    [timeQuery whereKey:@"user" equalTo:runner];
//    [timeQuery orderByDescending:@"updatedAt"];
//    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *runnerLocations, NSError *error) {
//        if (!error) {
//            // The find succeeded. The first 100 objects are available
//            //loop through all these possibly nearby runners and check distance
//            self.runnerPath = [NSMutableArray array];
//            for (PFObject *runnerLocEntry in runnerLocations) {
//                //getting location for a runner object
//                PFGeoPoint *point = [runnerLocEntry objectForKey:@"location"];
//                //converting location to CLLocation
//                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
//                //storing in location array
//                [self.runnerPath addObject: runnerLoc];
//            }
//            
//            //Add drawing of route line
//            [self.mapView removeAnnotations:self.mapView.annotations];
//            [self.mapView setShowsUserLocation:YES];
//            [self.mapView addAnnotation:self.runnerPath.firstObject];
//            [self drawLine];
//        }
//    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.targetPace resignFirstResponder];
    [self.raceTimeGoal resignFirstResponder];
    [self.bibNumber resignFirstResponder];
    [self.beaconName resignFirstResponder];

}

- (void)startLocationUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    self.locationManager.delegate = self;
    self.mapView.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.activityType = CLActivityTypeFitness;
    
    // Movement threshold for new events.
    self.locationManager.distanceFilter = 1; // meters
    
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *newLocation in locations) {
        if (newLocation.horizontalAccuracy < 0) return;
        
        else if (newLocation.horizontalAccuracy < 300) {
            if (self.locations.count > 0) {
                self.distance += [newLocation distanceFromLocation:self.locations.lastObject];
            }
        
            [self.locations addObject:newLocation];
    
        }
    }
}

- (void)saveRun
{
    Run *newRun = [NSEntityDescription insertNewObjectForEntityForName:@"Run"
                                                inManagedObjectContext:self.managedObjectContext];
    
    newRun.distance = [NSNumber numberWithFloat:self.distance];
    newRun.duration = [NSNumber numberWithInt:self.seconds];
    newRun.timestamp = [NSDate date];
    
    NSMutableArray *locationArray = [NSMutableArray array];
    for (CLLocation *location in self.locations) {
        Location *locationObject = [NSEntityDescription insertNewObjectForEntityForName:@"Location"
                                                                 inManagedObjectContext:self.managedObjectContext];
        
        locationObject.timestamp = location.timestamp;
        locationObject.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
        locationObject.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
        [locationArray addObject:locationObject];
    }
    
    newRun.locations = [NSOrderedSet orderedSetWithArray:locationArray];
    self.run = newRun;
    
    // Save the context.
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
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
