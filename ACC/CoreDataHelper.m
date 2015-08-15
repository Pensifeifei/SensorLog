//
//  CoreDataHelper.m
//  ACC
//
//  Created by Mr.Chang on 15/7/9.
//  Copyright (c) 2015年 Mr.Chang. All rights reserved.
//

#import "CoreDataHelper.h"

@implementation CoreDataHelper

#define debug 1

#pragma mark - FILES
//NSString *storeFileName = @"ACC-Data.sqlite";

#pragma mark - PATHS

- (NSString *) applicationDocumentsDirectory
{
    if (debug == 1) {
        MARK;
    }
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSURL *) applicationStoresDirectory{
    if (debug == 1) {
        MARK;
    }
    NSURL *storesDirectory = [[NSURL fileURLWithPath:[self applicationDocumentsDirectory]]URLByAppendingPathComponent:@"Stores"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[storesDirectory path]]) {
        NSError *error = nil;
        if ([fileManager createDirectoryAtURL:storesDirectory
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error]) {
            if (debug == 1) {
                NSLog(@"Successfully created Stores directory");
            }
            else {
                NSLog(@"FAILED to create Stores directory:%@",error);
            }
        }
    }
    return storesDirectory;
}

- (NSURL *) storeURL
{
    if (debug == 1) {
        MARK;
    }
    NSLog(@"storeFileName............%@",self.storeFileName);
    return [[self applicationStoresDirectory]URLByAppendingPathComponent:self.storeFileName];
}

#pragma mark - SETUP
- (id) init
{
    if (debug == 1) {
        MARK;
    }
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:_managedObjectModel];
    _managedObjectContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    
    return self;
}

- (void) loadStore{
    if (debug == 1 ) {
        MARK;
    }
    if (_persistentStore) {
        return;
    }
    NSDictionary *options = @{NSSQLitePragmasOption:@{@"journal_mode":@"DELETE"}};
    NSError *error = nil;
    _persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                 configuration:nil
                                                                           URL:[self storeURL]
                                                                       options:options
                                                                         error:&error];
    if (!_persistentStore) {
        NSLog(@"Failed to add store. Error:%@", error);
        abort();
    }
    else {
        if(debug == 1)
        {NSLog(@"Successfully add store: %@",_persistentStore);}
    }
}

- (void) setupCoreData{
    if (debug == 1) {
        MARK;
    }
    [self loadStore];
}

- (void) saveContext
{
    if (debug == 1) {
        MARK;
    }
    if ([_managedObjectContext hasChanges]) {
        NSError *error = nil;
        if ([_managedObjectContext save:&error]) {
            NSLog(@"_managedObjectContext SAVED changes to persistent store");
        }
        else{
            NSLog(@"Failed to save _managedObjectContext: %@",error);
        }
    }
    else{
        NSLog(@"SKIPPED _managedObjectContext save ,there are no changes!");
    }
}
@end
