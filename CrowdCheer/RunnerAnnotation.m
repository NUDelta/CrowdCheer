//
//  RunnerAnnotation.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 8/24/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "RunnerAnnotation.h"

@implementation RunnerAnnotation

-(id)initWithTitle:(NSString *)newTitle Location:(CLLocationCoordinate2D)location RunnerID:(NSString *)runnerID
{
    self = [super init];
    if(self)
    {
        _title = newTitle;
        _coordinate = location;
        _runnerObjID = runnerID;
    }
    return self;
}

-(MKAnnotationView *)annotationView
{
    UIButton *cheerBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [cheerBtn setTitle:@"Cheer!" forState:UIControlStateNormal];
    
    MKAnnotationView *annotationView = [[MKAnnotationView alloc]initWithAnnotation:self reuseIdentifier:@"RunnerAnnotation"];
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    annotationView.image = [UIImage imageNamed:@"runner.png"];
    annotationView.rightCalloutAccessoryView = cheerBtn;
    
    return annotationView;
}

@end
