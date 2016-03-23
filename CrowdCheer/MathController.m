//
//  MathController.m
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/9/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import "MathController.h"
//#import "Location.h"
//#import "MulticolorPolylineSegment.h"
//#import "Run.h"


static bool const isMetric = NO;
static float const metersInKM = 1000;
static float const metersInMile = 1609.344;

@implementation MathController

+ (NSString *)stringifyDistance:(float)meters
{
    float unitDivider;
    NSString *unitName;
    
    // metric
    if (isMetric) {
        unitName = @"km";
        // to get from meters to kilometers divide by this
        unitDivider = metersInKM;
        // U.S.
    } else {
        unitName = @"mi";
        // to get from meters to miles divide by this
        unitDivider = metersInMile;
    }
    
    return [NSString stringWithFormat:@"%.2f %@", (meters / unitDivider), unitName];
}

+ (NSString *)stringifySecondCount:(int)seconds usingLongFormat:(BOOL)longFormat
{
    int remainingSeconds = seconds;
    int hours = remainingSeconds / 3600;
    remainingSeconds = remainingSeconds - hours * 3600;
    int minutes = remainingSeconds / 60;
    remainingSeconds = remainingSeconds - minutes * 60;
    
    if (longFormat) {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%ihr %imin %isec", hours, minutes, remainingSeconds];
        } else if (minutes > 0) {
            return [NSString stringWithFormat:@"%imin %isec", minutes, remainingSeconds];
        } else {
            return [NSString stringWithFormat:@"%isec", remainingSeconds];
        }
    } else {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, remainingSeconds];
        } else if (minutes > 0) {
            return [NSString stringWithFormat:@"%02i:%02i", minutes, remainingSeconds];
        } else {
            return [NSString stringWithFormat:@"00:%02i", remainingSeconds];
        }
    }
}

+ (NSString *)stringifyAvgPaceFromDist:(float)meters overTime:(NSInteger)seconds
{
    if (seconds == 0 || meters == 0) {
        return @"0";
    }
    
    float avgPaceSecMeters = seconds / meters;
    
    float unitMultiplier;
    NSString *unitName;
    
    // metric
    if (isMetric) {
        unitName = @"min/km";
        unitMultiplier = metersInKM;
        // U.S.
    } else {
        unitName = @"min/mi";
        unitMultiplier = metersInMile;
    }
    
    int paceMin = (int) ((avgPaceSecMeters * unitMultiplier) / 60);
    int paceSec = (int) (avgPaceSecMeters * unitMultiplier - (paceMin*60));
    
    return [NSString stringWithFormat:@"%i:%02i %@", paceMin, paceSec, unitName];
}

@end
