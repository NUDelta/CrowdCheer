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

@property (nonatomic, strong) Run *run;

@property int seconds;
@property float distance;
@property NSString *pace;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, weak) IBOutlet UILabel *promptLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *distLabel;
@property (nonatomic, weak) IBOutlet UILabel *paceLabel;
@property (nonatomic, weak) IBOutlet UILabel *targetLabel;
@property (nonatomic, weak) IBOutlet UIButton *startButton;
@property (nonatomic, weak) IBOutlet UIButton *stopButton;

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
