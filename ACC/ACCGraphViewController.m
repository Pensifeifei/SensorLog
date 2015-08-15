//
//  ACCGraphViewController.m
//  ACC
//
//  Created by Mr.Chang on 15/7/30.
//  Copyright © 2015年 Mr.Chang. All rights reserved.
//

#import "ACCGraphViewController.h"
#import "AppDelegate.h"
#import "APLGraphView.h"
#import "ACCitem.h"
#import "CoreDataHelper.h"
#import "CHCSVParser.h"
#import "NSTimer+TimerBlocksSupport.h"

//static const NSTimeInterval accelerometerMin = 0.01;
static const double accelerometerHzMin = 1;

@interface ACCGraphViewController ()
{
    BOOL markFlag1;
    BOOL markFlag2;
    BOOL isRecord;
    
    // csv存储路径
    NSString *csvFilePath;
    
    NSTimer *timerOfRecord;
    float timeOfSeconds;
}

@property (nonatomic, weak) IBOutlet APLGraphView *graphView;
@property (weak, nonatomic) IBOutlet UIButton *setRecordingRateBtn;
@property (weak, nonatomic) IBOutlet UILabel *rateOfRecord;
@property (weak, nonatomic) IBOutlet UILabel *timeOfRecord;
@property (weak, nonatomic) IBOutlet UILabel *sizeOfRecordFile;

@property (weak, nonatomic) IBOutlet UIButton *mark1FlagBtn;
@property (weak, nonatomic) IBOutlet UIButton *mark2FlagBtn;
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordBtn;

@property (strong ,nonatomic) CoreDataHelper *cdh;

@end

@implementation ACCGraphViewController

#define debug 1

// coredata辅助类
-(CoreDataHelper *)cdh
{
    if (!_cdh) {
        _cdh = [CoreDataHelper new];
    }
    return _cdh;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    // Do any additional setup after loading the view.
}

#pragma mark - 加速度计的数据采集
- (void)setup
{
    self.updateIntervalSlider.enabled = NO;
    self.mark1FlagBtn.enabled = NO;
    self.mark2FlagBtn.enabled = NO;
    self.startRecordBtn.enabled = YES;
    self.stopRecordBtn.enabled = NO;
    markFlag1 = NO;
    markFlag2 = NO;
    isRecord = NO;
    
    self.rateOfRecord.text = @"1 Hz";
    timeOfSeconds = 0;
    self.timeOfRecord.text = [NSString stringWithFormat:@"%.1f S",timeOfSeconds];
    
    self.sizeOfRecordFile.text = @"0 Kb";
}

- (NSString *)toGetCurrentTimeToMiliSecondsStr
{
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    NSString *dateStr = [dateFormatter stringFromDate:date];
    return dateStr;
}

- (void)startUpdatesWithSliderValue:(int)sliderValue
{
//    NSTimeInterval delta = 0.005;
//    NSTimeInterval updateInterval = accelerometerMin + delta * sliderValue;
    int deltaHz = 1;
    int recordingRateHz = accelerometerHzMin + deltaHz * sliderValue;
    NSTimeInterval updateInterval = 1/recordingRateHz;
    
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] shareManager];
    CMQuaternion quat = mManager.deviceMotion.attitude.quaternion;
    
    ACCGraphViewController * __weak weakSelf = self;
    if ([mManager isAccelerometerAvailable] == YES) {
        [mManager setAccelerometerUpdateInterval:updateInterval];
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            [weakSelf.graphView addX:accelerometerData.acceleration.x y:accelerometerData.acceleration.y z:accelerometerData.acceleration.z];
            [weakSelf setLabelValueX:accelerometerData.acceleration.x y:accelerometerData.acceleration.y z:accelerometerData.acceleration.z];
            
            if (isRecord) {
                NSNumber *tempFlag = @0;
                if (markFlag1) {
                    tempFlag = @1;
                    markFlag1 = NO;
                }
                if (markFlag2) {
                    tempFlag = @2;
                    markFlag2 = NO;
                }
                //            NSLog(@"tempFlag    %@",tempFlag);
                //            NSLog(@"markFlag1   %d",markFlag1);
                //            NSLog(@"markFlag2   %d",markFlag2);
                NSString *dateStr = [self toGetCurrentTimeToMiliSecondsStr];
                            NSLog(@"date///%@",dateStr);
                ACCitem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ACCitem" inManagedObjectContext:self.cdh.managedObjectContext];
                newItem.acc_x = [NSNumber numberWithDouble:accelerometerData.acceleration.x];
                newItem.acc_y = [NSNumber numberWithDouble:accelerometerData.acceleration.y];
                newItem.acc_z = [NSNumber numberWithDouble:accelerometerData.acceleration.z];
                newItem.date = dateStr;
                newItem.mark_flag = tempFlag;
                newItem.quat_w = [NSNumber numberWithDouble:quat.w];
                newItem.quat_x = [NSNumber numberWithDouble:quat.x];
                newItem.quat_y = [NSNumber numberWithDouble:quat.y];
                newItem.quat_z = [NSNumber numberWithDouble:quat.z];
            }
        }];
    }
    
//    self.updateIntervalLabel.text = [NSString stringWithFormat:@"%f", updateInterval];
    self.updateIntervalLabel.text = [NSString stringWithFormat:@"%d Hz", recordingRateHz];
    
}

- (void)stopUpdates
{
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] shareManager];
    
    if ([mManager isAccelerometerActive] == YES) {
        [mManager stopAccelerometerUpdates];
    }
}
#pragma mark - 定时器

- (void)startTimer
{
    if (timerOfRecord) {
        [timerOfRecord invalidate];
        timerOfRecord = nil;
    }
    
    __weak ACCGraphViewController *weakSelf = self;
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //        dispatch_async(dispatch_get_main_queue(), ^{
    timerOfRecord = [NSTimer timerBlocks_scheduledTimerWithTimerInteval:0.1
                                                                        block:^{
                                                                            ACCGraphViewController *strongSelf = weakSelf;
                                                                            timeOfSeconds = timeOfSeconds+0.1;
                                                                            strongSelf.timeOfRecord.text = [NSString stringWithFormat:@"%.1f S",timeOfSeconds];
                                                                            
//                                                                            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ACCitem"];
//                                                                            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
//                                                                            [request setSortDescriptors:[NSArray arrayWithObject:sort]];
//                                                                            NSArray *fetchObjects = [self.cdh.managedObjectContext executeFetchRequest:request error:nil];
//                                                                            
//                                                                            NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
//                                                                            CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:stream encoding:NSUTF8StringEncoding delimiter:','];
//                                                                            
//                                                                            for (ACCitem *item in fetchObjects) {
//                                                                                [writer writeLineOfFields:@[item.acc_x,item.acc_y,item.acc_z,item.mark_flag,item.date]];
//                                                                            }
//                                                                            [writer closeStream];
//                                                                            
//                                                                            NSData *buffer = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
//                                                                            NSString *output = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
//                                                                            unsigned long numberOfByte = [output lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
//                                                                            float fSize = numberOfByte/1024.0;
//                                                                            self.sizeOfRecordFile.text = [NSString stringWithFormat:@"%.1f Kb",fSize];
//                                                                            NSLog(@"%@",[NSString stringWithFormat:@"%.1f Kb",fSize]);
                                                                        }
                                                                      repeats:YES];
    //        });
    //    });
}
- (void)stopTimer
{
    if (timerOfRecord != nil) {
        //        [timerToCountSeconds setFireDate:[NSDate distantFuture]];
        [timerOfRecord invalidate];
        timerOfRecord = nil;
    }
}
#pragma mark - 生成csv的存储路径
- (NSString *) applicationDocumentsDirectory
{
    if (debug == 1) {
        MARK;
    }
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSString *) applicationStoresDirectory{
    if (debug == 1) {
        MARK;
    }
//    NSURL *storesDirectory = [[NSURL fileURLWithPath:[self applicationDocumentsDirectory]]URLByAppendingPathComponent:@"Stores"];
    NSString *storesDirectory = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"CsvStores"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:storesDirectory]) {
        NSError *error = nil;
        if ([fileManager createDirectoryAtPath:storesDirectory
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

-(NSString *)storePath:(NSString *)storeFileName
{
    if (debug == 1) {
        MARK;
    }
    NSLog(@"storeFileName............%@",storeFileName);
    return [[self applicationStoresDirectory]stringByAppendingPathComponent:storeFileName];
}

#pragma mark - button操作控制

- (IBAction)mark1:(UIButton *)sender {
    markFlag1 = YES;
    self.mark1FlagBtn.enabled = NO;
    self.mark2FlagBtn.enabled = YES;
}

- (IBAction)mark2:(UIButton *)sender {
    markFlag2 = YES;
    self.mark1FlagBtn.enabled = YES;
    self.mark2FlagBtn.enabled = NO;
}
- (IBAction)start:(UIButton *)sender {
    self.mark1FlagBtn.enabled = YES;
    self.startRecordBtn.enabled = NO;
    self.stopRecordBtn.enabled = YES;
    isRecord = YES;
    
    timeOfSeconds = 0;
    [self startTimer];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM_dd_HH-mm-ss"];
    NSString *dateStr = [dateFormatter stringFromDate:date];
    
//    self.cdh.storeFileName = [NSString stringWithFormat:@"%@data.sqlite",dateStr];
    csvFilePath = [self storePath:[NSString stringWithFormat:@"%@data.csv",dateStr]];
//    [self.cdh setupCoreData];
    

}
- (IBAction)stop:(UIButton *)sender {
    self.startRecordBtn.enabled = YES;
    self.stopRecordBtn.enabled = NO;
    self.mark1FlagBtn.enabled = NO;
    self.mark2FlagBtn.enabled = NO;
    isRecord = NO;
    
    [self stopTimer];
    
//    [self.cdh saveContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ACCitem"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSArray *fetchObjects = [self.cdh.managedObjectContext executeFetchRequest:request error:nil];
    
    NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
    CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:stream encoding:NSUTF8StringEncoding delimiter:','];
    
    for (ACCitem *item in fetchObjects) {
        [writer writeLineOfFields:@[item.acc_x,item.acc_y,item.acc_z,item.mark_flag,item.date,item.quat_w,item.quat_x,item.quat_y,item.quat_z]];
    }
    [writer closeStream];
    
    NSData *buffer = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    NSString *output = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
    [output writeToFile:csvFilePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:csvFilePath]) {
        NSDictionary *attrDict = [fm attributesOfItemAtPath:csvFilePath error:NULL];
        unsigned long long fileSize = [attrDict fileSize];
        float fFileSize = fileSize/1024.0;
        self.sizeOfRecordFile.text = [NSString stringWithFormat:@"%.1f Kb",fFileSize];
        NSLog(@"sizeOfRecordFile%@",[NSString stringWithFormat:@"%.1f Kb",fFileSize]);
    }
    
    self.cdh = nil;
    
    
}

- (IBAction)setRecordingRate:(UIButton *)sender {
    if(self.setRecordingRateBtn.selected){
        self.setRecordingRateBtn.selected = NO;
        self.updateIntervalSlider.enabled = NO;
        self.startRecordBtn.enabled = YES;
        self.rateOfRecord.text = self.updateIntervalLabel.text;
    }
    else {
        self.setRecordingRateBtn.selected = YES;
        self.updateIntervalSlider.enabled = YES;
        self.startRecordBtn.enabled = NO;
    }
}

- (void)setSetRecordingRateBtn:(UIButton *)setRecordingRateBtn
{
    _setRecordingRateBtn = setRecordingRateBtn;
    [_setRecordingRateBtn setBackgroundImage:[self imageWithColor:[UIColor yellowColor]] forState:UIControlStateNormal];
    [_setRecordingRateBtn setTitle:@"setting" forState:UIControlStateNormal];
    [_setRecordingRateBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    [_setRecordingRateBtn setBackgroundImage:[self imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateSelected];
    [_setRecordingRateBtn setTitle:@"OK" forState:UIControlStateSelected];
    [_setRecordingRateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
}

#pragma mark - button colorset

-  (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end
