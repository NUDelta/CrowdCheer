//
//  CommonalityViewController.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 3/5/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "CommonalityViewController.h"
#import "NewRunViewController.h"

@interface CommonalityViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic, weak) IBOutlet UIButton *takePhoto;
@property (nonatomic, weak) IBOutlet UIButton *uploadPhoto;
@property (nonatomic, weak) IBOutlet UIButton *infoButton;

@property (strong, nonatomic) IBOutlet UIPickerView *monthPicker;
@property (strong, nonatomic) NSArray *monthArray;

@property (strong, nonatomic) IBOutlet UIPickerView *dayPicker;
@property (strong, nonatomic) NSArray *dayArray;

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *birthMonth;
@property (weak, nonatomic) IBOutlet UITextField *birthDay;

@property (nonatomic, weak) IBOutlet UIButton *cubs;
@property (nonatomic, weak) IBOutlet UIButton *sox;
@property (nonatomic, weak) IBOutlet UIButton *nike;
@property (nonatomic, weak) IBOutlet UIButton *reebok;
@property (nonatomic, weak) IBOutlet UIButton *coffee;
@property (nonatomic, weak) IBOutlet UIButton *tea;
@property (nonatomic, weak) IBOutlet UIButton *dogs;
@property (nonatomic, weak) IBOutlet UIButton *cats;
@property (nonatomic, weak) IBOutlet UIButton *hot;
@property (nonatomic, weak) IBOutlet UIButton *cold;


@end

@implementation CommonalityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.monthArray  = [[NSArray alloc] initWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December", nil];
    self.dayArray  = [[NSArray alloc] initWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22", @"23", @"24", @"25", @"26", @"27", @"28", @"29", @"30", @"31", nil];
    
    self.monthPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    self.dayPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    
    [self attachPickerToTextField:self.birthMonth :self.monthPicker];
    [self attachPickerToTextField:self.birthDay :self.dayPicker];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)infoButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Photo" message:@"We recommend taking a race day photo so your cheerers can recognize you on the course!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}


- (IBAction)takePhoto:(UIButton *)sender {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        
        [myAlertView show];
        
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
    
    
}

- (IBAction)selectPhoto:(UIButton *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
    
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;
    
    //Save photo to Parse profile
    NSData *imageData = UIImagePNGRepresentation(chosenImage);
    PFFile *imageFile = [PFFile fileWithName:@"image.png" data:imageData];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"profilePic"] = imageFile;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)attachPickerToTextField: (UITextField*) textField :(UIPickerView*) picker{
    picker.delegate = self;
    picker.dataSource = self;
    
    textField.delegate = self;
    textField.inputView = picker;
    
}

// let tapping on the background (off the input field) close the thing
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.birthMonth resignFirstResponder];
    [self.birthDay resignFirstResponder];
    
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.monthPicker){
        return self.monthArray.count;
    }
    else if (pickerView == self.dayPicker){
        return self.dayArray.count;
    }
    
    return 0;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row   forComponent:(NSInteger)component
{
    if (pickerView == self.monthPicker){
        return [self.monthArray objectAtIndex:row];
    }
    else if (pickerView == self.dayPicker){
        return [self.dayArray objectAtIndex:row];
    }
    
    return @"???";
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row   inComponent:(NSInteger)component
{
    PFUser *currentUser = [PFUser currentUser];

    if (pickerView == self.monthPicker){
        self.birthMonth.text = [self.monthArray objectAtIndex:row];
        currentUser[@"birthMonth"] = self.birthMonth.text;
    }
    else if (pickerView == self.dayPicker){
        self.birthDay.text = [self.dayArray objectAtIndex:row];
        currentUser[@"birthDay"] = self.birthDay.text;
    }
    currentUser[@"name"] = self.name.text;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
    
}

- (IBAction)cubs:(id)sender {
    [_cubs setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_sox setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_one"] = @1;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)sox:(id)sender {
    [_sox setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_cubs setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_one"] = @0;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)nike:(id)sender {
    [_nike setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_reebok setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_two"] = @1;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)reebok:(id)sender {
    [_reebok setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_nike setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_two"] = @0;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)coffee:(id)sender {
    [_coffee setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_tea setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_three"] = @1;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)tea:(id)sender {
    [_tea setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_coffee setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_three"] = @0;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)dogs:(id)sender {
    [_dogs setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_cats setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_four"] = @1;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)cats:(id)sender {
    [_cats setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_dogs setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_four"] = @0;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)hot:(id)sender {
    [_hot setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_cold setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_five"] = @1;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}

- (IBAction)cold:(id)sender {
    [_cold setBackgroundImage:[UIImage imageNamed:@"green-btn.png"] forState:UIControlStateNormal];
    [_hot setBackgroundImage:[UIImage imageNamed:@"blue-btn.png"] forState:UIControlStateNormal];
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"q_five"] = @0;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // The object has been saved.
        } else {
            // There was a problem, check error.description
        }
    }];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *nextController = [segue destinationViewController];
    if ([nextController isKindOfClass:[NewRunViewController class]]) {
        ((NewRunViewController *) nextController).managedObjectContext = self.managedObjectContext;
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
