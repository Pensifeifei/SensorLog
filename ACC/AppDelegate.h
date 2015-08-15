//
//  AppDelegate.h
//  ACC
//
//  Created by Mr.Chang on 15/7/9.
//  Copyright (c) 2015年 Mr.Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "CoreDataHelper.h"
#import <CoreMotion/CoreMotion.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//@property (strong, readonly, nonatomic) CoreDataHelper *coreDataHelper;

@property (strong, readonly, nonatomic) CMMotionManager *shareManager;


@end

