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
#import <Parse/Parse.h>
#import <Parse/PFGeoPoint.h>

@interface RelationshipViewController () <UIActionSheetDelegate, CLLocationManagerDelegate>


@property int seconds;
@property float distance;
@property NSString *pace;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, weak) IBOutlet UILabel *goalPace;

@end


@implementation RelationshipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
