//
//  MySignUpViewController.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/24/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "MySignUpViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MySignUpViewController ()

@end

@implementation MySignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"inShape_background.png"]];
    [self.view addSubview:backgroundView];
//    self.signUpView.logo = [UIImage imageNamed:@"helper.png"];
    
//    self.view.backgroundColor = [UIColor whiteColor];
//    UIImageView *logoView = [[UIImageView alloc] initWithImage:@"icon.png"];
//    self.signUpView.logo = [UIImage imageNamed:@"icon.png"];
    
    
    //[self.signUpView.signUpButton setTitle:@"" forState:UIControlStateNormal];
    //[self.signUpView.signUpButton setTitle:@"" forState:UIControlStateHighlighted];
    
    // Add background for fields
    
    // Remove text shadow
    CALayer *layer = self.signUpView.usernameField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.signUpView.passwordField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.signUpView.emailField.layer;
    layer.shadowOpacity = 0.0f;
    //    layer = self.signUpView.additionalField.layer;
    //    layer.shadowOpacity = 0.0f;
    
    // Set text color
    [self.signUpView.usernameField setTextColor:[UIColor whiteColor]];
    [self.signUpView.passwordField setTextColor:[UIColor whiteColor]];
    [self.signUpView.emailField setTextColor:[UIColor whiteColor]];
    //    [self.signUpView.additionalField setTextColor:[UIColor whiteColor]];
    
    // Change "Additional" to match our use
    //    [self.signUpView.additionalField setPlaceholder:@"Phone number"];
    //    [self.signUpView.additionalField setValue:[UIColor lightGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    float yOffset = [UIScreen mainScreen].bounds.size.height <= 480.0f ? 30.0f : 0.0f;
    
    CGRect fieldFrame = self.signUpView.usernameField.frame;
    
    [self.signUpView.dismissButton setFrame:CGRectMake(10.0f, 10.0f, 87.5f, 45.5f)];
   // [self.signUpView.logo setFrame:CGRectMake(66.5f, 70.0f, 187.0f, 58.5f)];
    [self.signUpView.signUpButton setFrame:CGRectMake(35.0f, 385.0f, 250.0f, 40.0f)];
    //    [self.fieldsBackground setFrame:CGRectMake(35.0f, fieldFrame.origin.y + yOffset, 250.0f, 174.0f)];
    
    [self.signUpView.usernameField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
                                                       fieldFrame.origin.y + yOffset,
                                                       fieldFrame.size.width - 10.0f,
                                                       fieldFrame.size.height)];
    yOffset += fieldFrame.size.height;
    
    [self.signUpView.passwordField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
                                                       fieldFrame.origin.y + yOffset,
                                                       fieldFrame.size.width - 10.0f,
                                                       fieldFrame.size.height)];
    yOffset += fieldFrame.size.height;
    
    [self.signUpView.emailField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
                                                    fieldFrame.origin.y + yOffset,
                                                    fieldFrame.size.width - 10.0f,
                                                    fieldFrame.size.height)];
    yOffset += fieldFrame.size.height;
    
    [self.signUpView.additionalField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
                                                         fieldFrame.origin.y + yOffset,
                                                         fieldFrame.size.width - 10.0f,
                                                         fieldFrame.size.height)];
    
    // Move all fields down on smaller screen sizes
    //    float yOffset = [UIScreen mainScreen].bounds.size.height <= 480.0f ? 20.0f : 0.0f;
    //
    //    CGRect fieldFrame = self.signUpView.usernameField.frame;
    //
    //    [self.signUpView.dismissButton setFrame:CGRectMake(10.0f, 10.0f, 87.5f, 45.5f)];
    //    [self.signUpView.logo setFrame:CGRectMake(66.5f, 70.0f, 187.0f, 58.5f)];
       [self.signUpView.signUpButton setFrame:CGRectMake(fieldFrame.origin.x, 480.0f, 250.0f, 40.0f)];
       [self.signUpView.signUpButton setTitle:@"SIGN UP" forState:UIControlStateNormal];
    //
    //    [self.signUpView.usernameField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
    //                                                       fieldFrame.origin.y + yOffset,
    //                                                       fieldFrame.size.width - 10.0f,
    //                                                       fieldFrame.size.height)];
    //    yOffset += fieldFrame.size.height;
    //
    //    [self.signUpView.passwordField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
    //                                                       fieldFrame.origin.y + yOffset,
    //                                                       fieldFrame.size.width - 10.0f,
    //                                                       fieldFrame.size.height)];
    //    yOffset += fieldFrame.size.height;
    //
    //    [self.signUpView.emailField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
    //                                                    fieldFrame.origin.y + yOffset,
    //                                                    fieldFrame.size.width - 10.0f,
    //                                                    fieldFrame.size.height)];
    //    yOffset += fieldFrame.size.height;
    
    //    [self.signUpView.additionalField setFrame:CGRectMake(fieldFrame.origin.x + 5.0f,
    //                                                         fieldFrame.origin.y + yOffset,
    //                                                         fieldFrame.size.width - 10.0f,
    //                                                         fieldFrame.size.height)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

