//
//  RoleViewController.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/8/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "RoleViewController.h"

@interface RoleViewController ()
@property (nonatomic, weak) IBOutlet UIBarButtonItem *logOutButton;
@property (nonatomic, weak) IBOutlet UIButton *runnerRole;
@property (nonatomic, weak) IBOutlet UIButton *cheererRole;

@end

@implementation RoleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logOutButton:(id)sender {
    [PFUser logOut];
}

- (IBAction)runnerRole:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"role"] = @"runner";
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)cheererRole:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"role"] = @"cheerer";
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
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
