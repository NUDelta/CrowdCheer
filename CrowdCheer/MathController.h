//
//  MathController.h
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/9/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MathController : NSObject

+ (NSString *)stringifyDistance:(float)meters;
+ (NSString *)stringifySecondCount:(int)seconds usingLongFormat:(BOOL)longFormat;
+ (NSString *)stringifyAvgPaceFromDist:(float)meters overTime:(NSInteger)seconds;

@end
