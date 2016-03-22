////
////  CheererStartViewController.m
////  CrowdCheer
////
////  Created by Leesha Maliakal on 4/13/15.
////  Copyright (c) 2015 Delta Lab. All rights reserved.
////
//
//#import "CheererStartViewController.h"
//#import <Parse/Parse.h>
//
//@interface CheererStartViewController () <UITextFieldDelegate>
//
//@property (weak, nonatomic) IBOutlet UITextField *targetRunner;
//
//@end
//
//@implementation CheererStartViewController
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view.
//    
//    PFUser *user = [PFUser currentUser];
//    
//    NSString *targetRunner = user[@"targetRunner"];
//    
//    self.targetRunner.text = targetRunner;
//    
//    [self.targetRunner addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
//    
//}
//
//-(void)textFieldDidChange :(UITextField *)textField{
//    //save profile info to Parse
//    PFUser *currentUser = [PFUser currentUser];
//    if (textField == self.targetRunner){
//        currentUser[@"targetRunner"] = self.targetRunner.text;
//    }
//    
//    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            // The object has been saved.
//        } else {
//            // There was a problem, check error.description
//        }
//    }];
//}
//
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    [self.targetRunner resignFirstResponder];
//    
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
///*
//#pragma mark - Navigation
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//}
//*/
//
//@end
