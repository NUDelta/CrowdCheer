//
//  DetailViewController.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/8/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//


#import "DetailViewController.h"
#import <MapKit/MapKit.h>
#import "MathController.h"
#import "Run.h"
#import "Location.h"
#import "MulticolorPolylineSegment.h"
#import "NewRunViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>

@interface DetailViewController () <MKMapViewDelegate>

@property float distance;
@property float distanceTotal;
@property int timeTotal;

@property int seconds;
@property NSString *pace;


@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UILabel *distanceLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *paceLabel;


@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setRun:(Run *)run
{
    if (_run != run) {
        _run = run;
        [self configureView];
    }
}

- (void)configureView
{
    self.distanceTotal = 0;
    self.timeTotal = 0;

    //need to retrieve data from Parse here
    PFUser *currentUser = [PFUser currentUser];
    
    PFQuery *query = [PFQuery queryWithClassName:@"RunnerLocation"];
    [query whereKey:@"user" equalTo: currentUser];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d scores.", objects.count);
            // Do something with the found objects
            
            for (PFObject *object in objects) {
                NSLog(@"%@", object.objectId);
                
                float totalDist = [[object objectForKey:@"distance"] floatValue];
                int totalTime = [[object objectForKey:@"runTime"] intValue];
                
                if(totalDist > self.distanceTotal){
                    self.distanceTotal = totalDist;
                }
                
                if(totalTime > self.timeTotal){
                    self.timeTotal = totalTime;
                }
            
                
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
    self.distanceLabel.text = [MathController stringifyDistance:self.distanceTotal];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    self.dateLabel.text = [formatter stringFromDate:self.run.timestamp];
    
    self.timeLabel.text = [NSString stringWithFormat:@"Time: %@",  [MathController stringifySecondCount:self.timeTotal usingLongFormat:YES]];
    
    self.paceLabel.text = [NSString stringWithFormat:@"Pace: %@",  [MathController stringifyAvgPaceFromDist:self.distanceTotal overTime:self.timeTotal]];
    
//    [self loadMap];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

- (MKCoordinateRegion)mapRegion
{
    MKCoordinateRegion region;
    Location *initialLoc = self.run.locations.firstObject;
    
    float minLat = initialLoc.latitude.floatValue;
    float minLng = initialLoc.longitude.floatValue;
    float maxLat = initialLoc.latitude.floatValue;
    float maxLng = initialLoc.longitude.floatValue;
    
    for (Location *location in self.run.locations) {
        if (location.latitude.floatValue < minLat) {
            minLat = location.latitude.floatValue;
        }
        if (location.longitude.floatValue < minLng) {
            minLng = location.longitude.floatValue;
        }
        if (location.latitude.floatValue > maxLat) {
            maxLat = location.latitude.floatValue;
        }
        if (location.longitude.floatValue > maxLng) {
            maxLng = location.longitude.floatValue;
        }
    }
    
    region.center.latitude = (minLat + maxLat) / 2.0f;
    region.center.longitude = (minLng + maxLng) / 2.0f;
    
    region.span.latitudeDelta = (maxLat - minLat) * 1.1f; // 10% padding
    region.span.longitudeDelta = (maxLng - minLng) * 1.1f; // 10% padding
    
    return region;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if ([overlay isKindOfClass:[MulticolorPolylineSegment class]]) {
        MulticolorPolylineSegment *polyLine = (MulticolorPolylineSegment *)overlay;
        MKPolylineRenderer *aRenderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
        aRenderer.strokeColor = polyLine.color;
        aRenderer.lineWidth = 3;
        return aRenderer;
    }
    
    return nil;
}

- (MKPolyline *)polyLine {
    
    CLLocationCoordinate2D coords[self.run.locations.count];
    
    for (int i = 0; i < self.run.locations.count; i++) {
        Location *location = [self.run.locations objectAtIndex:i];
        coords[i] = CLLocationCoordinate2DMake(location.latitude.doubleValue, location.longitude.doubleValue);
    }
    
    return [MKPolyline polylineWithCoordinates:coords count:self.run.locations.count];
}

//- (void)loadMap
//{
  //  if (self.run.locations.count > 0) {

    //    self.mapView.hidden = NO;
        
        // set the map bounds
      //  [self.mapView setRegion:[self mapRegion]];
        
        // make the line(s!) on the map
        //NSArray *colorSegmentArray = [MathController colorSegmentsForLocations:self.run.locations.array];
        //[self.mapView addOverlays:colorSegmentArray];
        
   // } else {
        
        // no locations were found!
     //   self.mapView.hidden = YES;
        
       // UIAlertView *alertView = [[UIAlertView alloc]
         //                         initWithTitle:@"Error"
           //                       message:@"Sorry, this run has no locations saved."
             //                     delegate:nil
               //                   cancelButtonTitle:@"OK"
                 //                 otherButtonTitles:nil];
       // [alertView show];
    //}
//}



@end