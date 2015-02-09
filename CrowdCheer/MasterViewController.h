//
//  MasterViewController.h
//  CrowdCheer
//
//  Created by Leesha Maliakal on 2/8/15.
//  Copyright (c) 2015 Delta Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end

