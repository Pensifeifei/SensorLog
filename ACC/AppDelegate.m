//
//  AppDelegate.m
//  ACC
//
//  Created by Mr.Chang on 15/7/9.
//  Copyright (c) 2015年 Mr.Chang. All rights reserved.
//

#import "AppDelegate.h"
//#import "ACCitem.h"
#import "APLGraphViewController.h"

@interface AppDelegate ()

{
    CMMotionManager *motionManager;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//    [[self cdh] saveContext];

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
//    [self cdh];
//    [self demo];
}

- (void)applicationWillTerminate:(UIApplication *)application {
//    [[self cdh] saveContext];

}

#pragma mark - coreData

#define debug 1

//- (CoreDataHelper *)cdh
//{
//    if (debug == 1) {
//        MARK;
//    }
//    if (!_coreDataHelper) {
//        _coreDataHelper = [CoreDataHelper new];
//        _coreDataHelper.storeFileName = @"ACC-Data.sqlite";
//        [_coreDataHelper setupCoreData];
//    }
//    return _coreDataHelper;
//}

//- (void)demo
//{
//    if (debug == 1) {
//        MARK;
//    }
//    NSArray *newItemACC_Xs = [NSArray arrayWithObjects:@9.8, @9.9,@9.7,@9.6,nil];
//    for(NSNumber *num in newItemACC_Xs){
//        ACCitem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ACCitem" inManagedObjectContext:_coreDataHelper.managedObjectContext];
//        newItem.acc_x = num;
//        NSLog(@"Insert New managed object for '%@'",newItem.acc_x);
//    }
//    
//}

#pragma mark - coreMotionManager

- (CMMotionManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        motionManager = [[CMMotionManager alloc] init];
    });
    return motionManager;
}

@end
