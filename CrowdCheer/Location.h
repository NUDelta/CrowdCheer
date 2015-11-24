//
//  Location.h
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/8/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSManagedObject *run;

@end
