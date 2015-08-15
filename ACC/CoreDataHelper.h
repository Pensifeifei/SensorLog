//
//  CoreDataHelper.h
//  ACC
//
//  Created by Mr.Chang on 15/7/9.
//  Copyright (c) 2015年 Mr.Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataHelper : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSPersistentStore *persistentStore;

@property (readwrite,retain ,nonatomic )NSString *storeFileName;

- (void) setupCoreData;
- (void) saveContext;
- (NSURL *) storeURL;


@end
