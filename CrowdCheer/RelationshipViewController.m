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


@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;



@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *bibLabel;
@property (nonatomic, weak) IBOutlet UILabel *commonalityLabel;

@end


@implementation RelationshipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Once we have the Runner's account as user, we can use this code to pull data for the motivator:
    NSString *userObjectID = [self.userInfo objectForKey:@"objectId"];
    NSLog(@"User ID passed to RVC is %@""", userObjectID);
    PFQuery *query = [PFUser query];
    PFUser *user = (PFUser *)[query getObjectWithId:userObjectID];
    NSLog(@"User passed to RVC is %@", user);
    
    
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
        
        NSString *name = user[@"name"];
        NSString *bibNumber = user[@"bibNumber"];
        NSString *commonality = user[@"display commonality here"];
        NSLog(name);
        
        _nameLabel.text = name;
        _bibLabel.text = bibNumber;
        _commonalityLabel.text = commonality;
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

    //self.commonalityLabel.hidden = NO;
}

@end
