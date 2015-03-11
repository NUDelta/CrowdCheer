//
//  CommonalityViewController.h
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/5/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CommonalityViewController : UIViewController <UIAlertViewDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
