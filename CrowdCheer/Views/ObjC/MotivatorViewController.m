////
////  MotivatorViewController.m
////  CrowdCheer
////
////  Created by Scott Cambo on 3/2/15.
////  Modified by Leesha Maliakal
////  Copyright (c) 2015 Delta Lab. All rights reserved.
////
//
//#import "MotivatorViewController.h"
//#import "RelationshipViewController.h"
//#import "RunnerAnnotation.h"
//#import "MyRunnerAnnotation.h"
//#import <Parse/Parse.h>
//#import <Parse/PFGeoPoint.h>
//#import <MapKit/MapKit.h>
//
//static NSString * const detailSegueName = @"RelationshipView";
//
//@interface MotivatorViewController () <UIActionSheetDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, MKMapViewDelegate>
//
//{
//    dispatch_queue_t checkQueue;
//}
//@property (nonatomic, strong) NSTimer *isCheckingRunners;
//@property (nonatomic, strong) NSTimer *isCheckingMyRunner;
//@property (nonatomic, strong) CLLocationManager *locationManager;
//@property (nonatomic, strong) CLLocation *locations;
//@property (nonatomic, readwrite) MKPolyline *polyline; //your line
//@property (nonatomic, readwrite) MKPolylineView *lineView; //your line view
//@property (nonatomic, strong) NSMutableArray *runnerPath;
//@property (nonatomic, strong) NSMutableArray *runnerDist;
//@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;
//@property (weak, nonatomic) IBOutlet MKMapView *mapView;
//@property (weak, nonatomic) IBOutlet UIButton *cheerButton;
//@property int radius1;
//@property int radius2;
//@property int radius3;
//@property int radius4;
//@property int radius5;
//@property int radius6;
//@property int radius7;
//@property int radius8;
//@property int major;
//@property int minor;
//@property (strong, nonatomic) NSString *runnerObjId;
//@property (weak, nonatomic) PFUser *cheerer;
//@property (weak, nonatomic) PFUser *runner;
//
//@end
//
//@implementation MotivatorViewController
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    
//    //radius in meters, smaller index = closer to runner
//    self.radius1 = 10; //10
//    self.radius2 = 50; //50
//    self.radius3 = 100;//100
//    self.radius4 = 200;//200
//    self.radius5 = 300;//300
//    self.radius6 = 400;//400
//    self.radius7 = 500;//500
//    self.radius8 = 1000;//1000
//    
//    //Step 1a: initialize checking runner timers
//    NSLog(@"isCheckingRunners started");
//    self.isCheckingRunners = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self
//                                                            selector:@selector(findRunners) userInfo:nil repeats:YES];
//    self.isCheckingMyRunner = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self
//                                                             selector:@selector(findMyRunner) userInfo:nil repeats:YES];
//    
//    [self startLocationUpdates];
//    self.cheerer = [PFUser currentUser];
//    
//    //UI Setup:
//    self.cheerButton.enabled  = NO;
//    [self.cheerButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
//    [self.cheerButton setTitle:@"Get ready to cheer!" forState:UIControlStateNormal];
//    self.rangeLabel.hidden = YES;
//    
//}
//
//
//- (void)viewDidAppear:(BOOL)animated {
//    
//    //radius in meters, smaller index = closer to runner
//    self.radius1 = 10; //10
//    self.radius2 = 50; //50
//    self.radius3 = 100;//100
//    self.radius4 = 200;//200
//    self.radius5 = 300;//300
//    self.radius6 = 400;//400
//    self.radius7 = 500;//500
//    self.radius8 = 1000;//1000
//    
//    //Step 1a: initialize checking runner timers
//    NSLog(@"isCheckingRunners started");
//    self.isCheckingRunners = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self
//                                                            selector:@selector(findRunners) userInfo:nil repeats:YES];
//    self.isCheckingMyRunner = [NSTimer scheduledTimerWithTimeInterval:(5.0) target:self
//                                                             selector:@selector(findMyRunner) userInfo:nil repeats:YES];
//    
//    [self startLocationUpdates];
//    self.cheerer = [PFUser currentUser];
//    
//    //UI Setup:
//    self.cheerButton.enabled  = NO;
//    [self.cheerButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
//    [self.cheerButton setTitle:@"Get ready to cheer!" forState:UIControlStateNormal];
//    self.rangeLabel.hidden = YES;
//}
//
//
//- (void)viewDidDisappear:(BOOL)animated {
//    [self.isCheckingRunners invalidate];
//    NSLog(@"invalidated isCheckingRunners");
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
////findMyRunner()
//- (void)findMyRunner {
//    NSLog(@"findMyRunner()");
//    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
//    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
//    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];//First check for runners who have updated information recently
//    [timeQuery orderByAscending:@"updatedAt"];
//    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *possibleNearbyRunners, NSError *error) { //if there are any objects found, create an array and execute block
//        if (!error) {
//            // The find succeeded. The first 100 objects are available
//            for (PFObject *possible in possibleNearbyRunners) { //loop through all these possibly nearby runners and first check if it's our target, then check target's distance
//                NSLog(@"Searching for my runner...");
//                PFUser *runner = possible[@"user"];
//                [runner fetchIfNeeded];
//                NSString *runnerName = [runner objectForKey:@"name"];
//                NSString *runnerUsername = [runner objectForKey:@"username"];
//                NSString *targetUsername = [self.cheerer objectForKey:@"targetRunner"];
//                NSLog(@"Target: %@ Runner: %@", targetUsername, runnerUsername);
//                
//                if ([runnerUsername isEqualToString:targetUsername]) {
//                    NSLog(@"Target runner %@ was found", targetUsername);
//                    //calculate distance of target runner
//                    PFGeoPoint *point = [possible objectForKey:@"location"]; //getting location for a runner object
//                    CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //converting location to CLLocation
//                    CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; // distance in meters
//                    NSLog(@"Target runner's dist: %f", dist);
//                    
//                    //based on the distance between me and our possible runner, do the following:
//                    if ((dist <= self.radius7) && (dist > self.radius4)) {  //between radius 4 and 7
//                        NSLog(@"Target Runner Approaching");
//                        [self.isCheckingRunners invalidate];
//                        //remove any map annotations and only pin target runner
//                        [self.mapView removeAnnotations:self.mapView.annotations];
//                        [self.mapView setShowsUserLocation:YES];
//                        MyRunnerAnnotation *myRunnerAnnotation = [[MyRunnerAnnotation alloc]initWithTitle:runnerName Location:runnerLoc.coordinate RunnerID:runner.objectId];
//                        [self.mapView addAnnotation:myRunnerAnnotation];
//                        
//                        
//                        //notify cheerer of approaching target runner
////                        NSString* distString = [NSString stringWithFormat:@"%f", dist];
////                        NSString *alertMess =  [runnerName stringByAppendingFormat:@" is %.02fm away!", dist];
////                        NSDictionary *runnerDict = [NSDictionary dictionaryWithObjectsAndKeys:self.runnerObjId, @"user", runnerName, @"name", distString, @"distance", @"approaching", @"runnerStatus", nil];
////                        NSLog(@"runnerDict: %@", runnerDict);
////                        
////                        UIApplicationState state = [UIApplication sharedApplication].applicationState;
////                        NSLog(@"application state is %ld", (long)state);
////                        if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
////                        {
////                            // This code sends notification to didFinishLaunchingWithOptions in AppDelegate.m
////                            // userInfo can include the dictionary above called runnerDict
////                            [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated"
////                                                                                object:self
////                                                                              userInfo:runnerDict];
////                            
////                            NSLog(@" notifying about %@ from background", self.runnerObjId);
////                        }
////                        else {
////                            UIAlertView *cheerAlert = [[UIAlertView alloc] initWithTitle:alertMess message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
////                            NSLog(@"about to display cheerAlert");
////                            [cheerAlert show];
////                        }
//                    }
//                    else {
//                        NSLog(@"Target runner out of range");
//                    }
//
//                }
//                
//                else {
//                    NSLog(@"ERROR: Target runner was not found"); //outside range
//                }
//            }
//        }
//        
//        else {
//            NSLog(@"Error: %@ %@", error, [error userInfo]);  // Log details of the failure
//        }
//    }]; //end of find objects in background with block
//    NSLog(@"No runners found");
//    
//}
//
////findRunners()
//- (void)findRunners{
//    NSLog(@"findRunners()");
//    
//    //Step 1b: Every second, look for potential runners to cheer. Pick a runner if they are 400-500m away.
//    //add later - if potential runner is 1000-900m away, and if the runner is the cheerer's primary target, select this runner
//    NSMutableArray *possibleRunnersLoc = [[NSMutableArray alloc]init];
//    NSMutableArray *possibleRunners = [[NSMutableArray alloc]init];
//    NSMutableArray *possibleRunnersNames = [[NSMutableArray alloc]init];
//    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
//    NSDate *then = [NSDate dateWithTimeIntervalSinceNow:-10];
//    [timeQuery whereKey:@"updatedAt" greaterThanOrEqualTo:then];//First check for runners who have updated information recently
//    [timeQuery orderByAscending:@"updatedAt"];
//    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *possibleNearbyRunners, NSError *error) { //if there are any objects found, create an array and execute block
//        if (!error) {
//            // The find succeeded. The first 100 objects are available
//            for (PFObject *possible in possibleNearbyRunners) { //loop through all these possibly nearby runners and check distance
//                NSLog(@"Looping through runners...");
//                PFGeoPoint *point = [possible objectForKey:@"location"]; //getting location for a runner object
//                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude]; //converting location to CLLocation
//                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; // distance in meters
//                NSLog(@"possible's dist: %f", dist);
//                
//                //based on the distance between me and our possible runner, do the following:
//                if ((dist <= self.radius7) && (dist > self.radius4)) {  //between radius 4 and 7
//                    PFUser *runner = possible[@"user"];
//                    [runner fetchIfNeeded];
//                    NSString *runnerName = [runner objectForKey:@"name"];
//                    
//                    if([possibleRunnersNames containsObject:runnerName]) {
//                        //skip runner
//                    }
//                    else {
//                        [possibleRunners addObject:runner];
//                        [possibleRunnersNames addObject:runnerName];
//                        [possibleRunnersLoc addObject:runnerLoc];
//                    }
//                    
//                }
//                else {
//                    
//                    NSLog(@"Runner out of range"); //outside range
//                }
////                break; //exiting for loop
//            }
//            
//
//            //remove existing possible runner pins
//            [self.mapView removeAnnotations:self.mapView.annotations];
//            [self.mapView setShowsUserLocation:YES];
//            NSLog(@"possible runners: %@", possibleRunnersNames);
//            //here, we should update the map with any unique runner that is in this radius shell
//            //display each runner's location & name
//            for (PFUser *runner in possibleRunners) {
//                NSString *runnerName = [runner objectForKey:@"name"];
//                for (CLLocation *runnerLoc in possibleRunnersLoc) {
//                    RunnerAnnotation *runnerAnnotation = [[RunnerAnnotation alloc]initWithTitle:runnerName Location:runnerLoc.coordinate RunnerID:runner.objectId];
//                    [self.mapView addAnnotation:runnerAnnotation];
//                    //plot routes of each runner in different colors?
//                }
//            }
//        }
//     else {
//            NSLog(@"Error: %@ %@", error, [error userInfo]);  // Log details of the failure
//        }
//    }]; //end of find objects in background with block
//    NSLog(@"No runners found");
//}
//
//- (MKAnnotationView *)mapView:(MKMapView *)mapView
//            viewForAnnotation:(id <MKAnnotation>)annotation
//{
//    // If the annotation is the user location, just return nil.
//    if ([annotation isKindOfClass:[MKUserLocation class]])
//        return nil;
//    
//    // Handle any custom annotations.
//    if ([annotation isKindOfClass:[RunnerAnnotation class]])
//    {
//        RunnerAnnotation *loc = (RunnerAnnotation *)annotation;
//        // Try to dequeue an existing pin view first.
//        MKAnnotationView*    annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"RunnerAnnotationView"];
//        
//        if (!annotationView)
//        {
//            // If an existing pin view was not available, create one.
//            annotationView = loc.annotationView;
//        }
//        else
//            annotationView.annotation = annotation;
//        
//        return annotationView;
//    }
//    
//    else if ([annotation isKindOfClass:[MyRunnerAnnotation class]])
//    {
//        MyRunnerAnnotation *loc = (MyRunnerAnnotation *)annotation;
//        // Try to dequeue an existing pin view first.
//        MKAnnotationView*    annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MyRunnerAnnotationView"];
//        
//        if (!annotationView)
//        {
//            // If an existing pin view was not available, create one.
//            annotationView = loc.annotationView;
//        }
//        else
//            annotationView.annotation = annotation;
//        
//        return annotationView;
//    }
//    
//    return nil;
//}
//
//-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
//{
////    selecting a runner allows you to track them
////    once user selects runner
////    SEGUE to RVC for tracking OR
////    call runnerApproaching from here
//    //get annotation title & distance to annotation pin
//    RunnerAnnotation *ann = (RunnerAnnotation *)view.annotation;
//    NSString *runnerObjID = ann.runnerObjID;
//    PFQuery *query = [PFUser query];
//    self.runner = (PFUser *)[query getObjectWithId:runnerObjID];
//    PFUser *runnerTracked = self.runner;
//    NSLog(@"runner on info tap is: %@", self.runner.objectId);
//    
//    NSString *runnerName = [NSString stringWithFormat:@"%@",[runnerTracked objectForKey:@"name"]];
//    self.runnerObjId = runnerObjID;
//    [self.cheerButton setTitle:[NSString stringWithFormat:@"Follow %@!", runnerName] forState:UIControlStateNormal];
//    self.cheerButton.enabled = YES;
//
//}
//
////updateDistance(runner)
//- (void) updateDistance:(NSTimer*)timer {
//    NSDictionary *trackESArgs = (NSDictionary *)[timer userInfo];
//    PFUser *runnerTracked = [trackESArgs objectForKey:@"runner"];
//    
//    //Find any recent location updates from our runner
//    PFQuery *timeQuery = [PFQuery queryWithClassName:@"RunnerLocation"];
//    [timeQuery whereKey:@"user" equalTo:runnerTracked];
//    [timeQuery orderByDescending:@"updatedAt"];
//    [timeQuery findObjectsInBackgroundWithBlock:^(NSArray *runnerLocations, NSError *error) {
//        if (!error) {
//            // The find succeeded. The first 100 objects are available
//            //loop through all these possibly nearby runners and check distance
//            self.runnerDist = [NSMutableArray array];
//            self.runnerPath = [NSMutableArray array];
//            for (PFObject *runnerLocEntry in runnerLocations) {
//                //getting location for a runner object
//                PFGeoPoint *point = [runnerLocEntry objectForKey:@"location"];
//                //converting location to CLLocation
//                CLLocation *runnerLoc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
//                //storing in location array
//                [self.runnerPath addObject: runnerLoc];
//                //calculate distance and store in distance array
//                CLLocationDistance dist = [runnerLoc distanceFromLocation:self.locations]; //in meters
//                [self.runnerDist addObject:[NSNumber numberWithDouble:dist]];
//                if(self.runnerPath.count > 10) {
//                    break;
//                }
//            }
//            
//            //Add drawing of route line
//            [self.mapView removeAnnotations:self.mapView.annotations];
//            [self.mapView setShowsUserLocation:YES];
//            CLLocation *runnerLoc = self.runnerPath.firstObject;
//            CLLocationCoordinate2D runnerCoor = runnerLoc.coordinate;
//            RunnerAnnotation *runnerAnnotation = [[RunnerAnnotation alloc]initWithTitle:[NSString stringWithFormat:@"%@", runnerTracked.username] Location:runnerCoor RunnerID:runnerTracked.objectId];
//            [self.mapView addAnnotation:runnerAnnotation];
//            [self drawLine];
//            
//            
//            //update distance label
//            double dist = [self.runnerDist.firstObject doubleValue];
//            int distInt = (int)dist;
//            NSLog(@"runnerDist array: %@", self.runnerDist);
//            self.rangeLabel.hidden = NO;
//            self.rangeLabel.text = [NSString stringWithFormat:@"%@ is %d meters away", [runnerTracked objectForKey:@"name"], distInt]; //UI update - Runner is x meters and y minutes away
//        }
//    }];
//    
//}
//
//- (void)drawLine {
//    
//    // create an array of coordinates
//    CLLocationCoordinate2D coordinates[self.runnerPath.count];
//    int i = 0;
//    for (CLLocation *currentPin in self.runnerPath) {
//        coordinates[i] = currentPin.coordinate;
//        i++;
//    }
//    
//    // create a polyline with all cooridnates
//    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coordinates count:self.runnerPath.count];
//    [self.mapView addOverlay:polyline];
//    self.polyline = polyline;
//    
//    // create an MKPolylineView and add it to the map view
//    self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
//    self.lineView.strokeColor = [UIColor blueColor];
//    self.lineView.lineWidth = 3;
//    
//}
//
//- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
//    
//    return self.lineView;
//}
//
//
//-(IBAction)cheerPressed:(id)sender {
//    
////    PFObject *startCheering = [PFObject objectWithClassName:@"startCheeringTime"];
////    NSLog(self.runner, [PFUser currentUser]);
////    startCheering[@"runnerMotivated"] = self.runner; //runner is null here
////    startCheering[@"cheerer"] = [PFUser currentUser];
////    [startCheering saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
////        if (succeeded) {
////            NSLog(@"saved Cheering Time");
////        } else {
////            // There was a problem, check error.description
////        }
////    }];
//}
//
//
//- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
//    NSLog(@"button clicked!!!!");
//}
//
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
//    NSLog(@"%ld", (long)buttonIndex);
//    if ([buttonTitle isEqualToString:@"Cheer!"]) {
//        NSLog(@"the button is equal to cheer");
//        
//        [self performSegueWithIdentifier:@"relationshipSegue" sender:self];
//        
//    }
//}
//
//- (void)startLocationUpdates
//{
//    // Create the location manager if this object does not
//    // already have one.
//    if (self.locationManager == nil) {
//        self.locationManager = [[CLLocationManager alloc] init];
//    }
//    
//    self.locationManager.delegate = self;
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    self.locationManager.activityType = CLActivityTypeFitness;
//    
//    // Movement threshold for new events.
//    self.locationManager.distanceFilter = 1; // meters
//    
//    [self.locationManager requestWhenInUseAuthorization];
//    [self.locationManager requestAlwaysAuthorization];
//    [self.locationManager startUpdatingLocation];
//    
//    //setting up mapview
//    CLLocation *location = [self.locationManager location];
//    CLLocationCoordinate2D coordinate = [location coordinate];
//    self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, self.radius7*2.5, self.radius7*2.5);
//    [self.mapView removeAnnotations:self.mapView.annotations];
//    [self.mapView setShowsUserLocation:YES];
//    [self.mapView setDelegate:self];
//}
//
//- (void)locationManager:(CLLocationManager *)manager
//     didUpdateLocations:(NSArray *)locations
//{
//    CLLocation *newLocation = [locations lastObject];
//    self.locations = newLocation;
//    PFGeoPoint *loc  = [PFGeoPoint geoPointWithLocation:newLocation];
//    
//    PFObject *cheerLocation = [PFObject objectWithClassName:@"CheererLocation"];
//    [cheerLocation setObject:[[NSDate alloc] init] forKey:@"time"];
//    [cheerLocation setObject:loc forKey:@"location"];
//    [cheerLocation setObject:self.cheerer forKey:@"user"];
//    NSLog(@"CheererLocation is %@", loc);
//    
//    [cheerLocation saveInBackground];
//    
//}
//
//
//- (void)showAlarm:(NSNotification *)notification {
//    // showAlarm gets called from notification that is registered in didFinishLaunchingWithOptions at the top of this class
//    // this code was borrowed from http://www.appcoda.com/ios-programming-local-notification-tutorial/
//    NSLog(@"[AppleDelegate showAlarm] called");
//    
//    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
//    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
//    localNotification.alertBody = @"Your alert message";
//    localNotification.alertAction = @"AlertButtonCaption";
//    localNotification.soundName = UILocalNotificationDefaultSoundName;
//    localNotification.timeZone = [NSTimeZone defaultTimeZone];
//    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//}
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    
//    NSLog(@"prepareForSegue: %@", segue.identifier);
//    
//    if ([segue.identifier isEqualToString:@"relationshipSegue"]) {
//        [segue.destinationViewController setRunnerObjId:self.runnerObjId];
//        NSLog(@"==============Segueing with %@===============", self.runnerObjId);
//    }
//    else {
//         NSLog(@"==============SEGUE ERROR===============");
//    }
//}
//
//@end