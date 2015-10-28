//
//  MyRunnerAnnotation.h
//  CrowdCheer
//
//  Created by Leesha Maliakal on 8/24/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyRunnerAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (nonatomic, readonly) NSString *runnerObjID;

-(id)initWithTitle:(NSString *)newTitle Location:(CLLocationCoordinate2D)location RunnerID:(NSString *)runnerID;
-(MKAnnotationView *)annotationView;

@end
