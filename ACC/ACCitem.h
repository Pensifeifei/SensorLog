//
//  ACCitem.h
//  ACC
//
//  Created by Mr.Chang on 15/8/15.
//  Copyright (c) 2015年 Mr.Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ACCitem : NSManagedObject

@property (nonatomic, retain) NSNumber * acc_x;
@property (nonatomic, retain) NSNumber * acc_y;
@property (nonatomic, retain) NSNumber * acc_z;
@property (nonatomic, retain) NSNumber * gyro_x;
@property (nonatomic, retain) NSNumber * gyro_y;
@property (nonatomic, retain) NSNumber * gyro_z;
@property (nonatomic, retain) NSNumber * roll;
@property (nonatomic, retain) NSNumber * pitch;
@property (nonatomic, retain) NSNumber * yaw;
@property (nonatomic, retain) NSNumber * userAcc_x;
@property (nonatomic, retain) NSNumber * userAcc_y;
@property (nonatomic, retain) NSNumber * userAcc_z;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSNumber * mark_flag;
//@property (nonatomic, retain) NSString * quat_date;
//@property (nonatomic, retain) NSNumber * quat_w;
//@property (nonatomic, retain) NSNumber * quat_x;
//@property (nonatomic, retain) NSNumber * quat_y;
//@property (nonatomic, retain) NSNumber * quat_z;


@end
