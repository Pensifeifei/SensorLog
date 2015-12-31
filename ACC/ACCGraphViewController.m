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
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>


typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);
static const double accelerometerHzMin = 1;
static const int state0 = 0;
static const int state1 = 1;
static const int state2 = 2;
static const int state3 = 3;
static const int state4 = 4;

typedef enum {
    kDeviceMotionGraphTypeAttitude = 0,
    kDeviceMotionGraphTypeRotationRate,
    kDeviceMotionGraphTypeGravity,
    kDeviceMotionGraphTypeUserAcceleration
} DeviceMotionGraphType;

@interface ACCGraphViewController ()<AVCaptureFileOutputRecordingDelegate,RPPreviewViewControllerDelegate>//视频文件输出代理
{
    
    BOOL isRecord;
    int stateFlag;
    // csv存储路径
    NSString *csvFilePath;
    NSTimer *timerOfRecord;
    float timeOfSeconds;
    
    double gyro_x;
    double gyro_y;
    double gyro_z;
    double quat_w;
    double quat_x;
    double quat_y;
    double quat_z;
    NSString *quat_date;
    
}

@property (strong ,nonatomic) CoreDataHelper *cdh;
@property (weak, nonatomic) IBOutlet APLGraphView *graphViewACC;
@property (weak, nonatomic) IBOutlet APLGraphView *graphViewGRYO;

@property (weak, nonatomic) IBOutlet UIButton *setRecordingRateBtn;
@property (weak, nonatomic) IBOutlet UILabel *rateOfRecord;
@property (weak, nonatomic) IBOutlet UILabel *timeOfRecord;
@property (weak, nonatomic) IBOutlet UILabel *sizeOfRecordFile;

@property (weak, nonatomic) IBOutlet UIButton *stateFlag0Btn;
@property (weak, nonatomic) IBOutlet UIButton *stateFlag1Btn;
@property (weak, nonatomic) IBOutlet UIButton *stateFlag2Btn;
@property (weak, nonatomic) IBOutlet UIButton *stateFlag3Btn;
@property (weak, nonatomic) IBOutlet UIButton *stateFlag4Btn;
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordBtn;

@property (weak, nonatomic) IBOutlet UILabel *w;
@property (weak, nonatomic) IBOutlet UILabel *x;
@property (weak, nonatomic) IBOutlet UILabel *y;
@property (weak, nonatomic) IBOutlet UILabel *z;
@property (weak, nonatomic) IBOutlet UIView *viewContainer;

@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设备之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识


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
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self initCamera];
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}
/**
 *  摄像头初始化
 */
- (void)initCamera
{
    //初始化会话
    _captureSession=[[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {//设置分辨率
        _captureSession.sessionPreset=AVCaptureSessionPreset352x288;
    }
    //获得输入设备
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    if (!captureDevice) {
        NSLog(@"取得后置摄像头时出现问题.");
        return;
    }
    //添加一个音频输入设备
    //    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    //初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        //        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection=[_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported ]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CALayer *layer=self.viewContainer.layer;
    layer.masksToBounds=YES;
    
    _captureVideoPreviewLayer.frame=layer.bounds;
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    //将视频预览层添加到界面中
    [layer addSublayer:_captureVideoPreviewLayer];
}

#pragma mark - 加速度计的数据采集
- (void)setup
{
    self.updateIntervalSlider.enabled = NO;
    self.stateFlag0Btn.enabled = NO;
    self.stateFlag1Btn.enabled = YES;
    self.stateFlag2Btn.enabled = YES;
    self.stateFlag3Btn.enabled = YES;
    self.stateFlag4Btn.enabled = YES;
    self.startRecordBtn.enabled = YES;
    self.stopRecordBtn.enabled = NO;

    stateFlag = 0;
    isRecord = NO;
    self.rateOfRecord.text = @"1 Hz";
    timeOfSeconds = 0;
    self.timeOfRecord.text = [NSString stringWithFormat:@"%.1f S",timeOfSeconds];
    
    self.sizeOfRecordFile.text = @"0 Kb";
}
/**
 *  获取当前时间日期
 */
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
/**
 *  根据滑块启动传感器
 *
 *  @param sliderValue <#sliderValue description#>
 */
- (void)startUpdatesWithSliderValue:(int)sliderValue
{


    double recordingRateHz = accelerometerHzMin + sliderValue;
    NSTimeInterval updateInterval = (1/recordingRateHz);
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] shareManager];

    
    ACCGraphViewController * __weak weakSelf = self;
    if ([mManager isAccelerometerAvailable] == YES ) {
        [mManager setAccelerometerUpdateInterval:updateInterval];
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                [weakSelf.graphViewACC addX:accelerometerData.acceleration.x y:accelerometerData.acceleration.y z:accelerometerData.acceleration.z];
                [weakSelf setLabelValueX:accelerometerData.acceleration.x y:accelerometerData.acceleration.y z:accelerometerData.acceleration.z];

            if (isRecord) {
                NSNumber *tempFlag = [[NSNumber alloc]initWithInt:stateFlag];
                NSString *dateStr = [weakSelf toGetCurrentTimeToMiliSecondsStr];
                NSLog(@"acc----date///%@",dateStr);
                
                
                ACCitem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ACCitem" inManagedObjectContext:weakSelf.cdh.managedObjectContext];
                newItem.acc_x = [NSNumber numberWithDouble:accelerometerData.acceleration.x];
                newItem.acc_y = [NSNumber numberWithDouble:accelerometerData.acceleration.y];
                newItem.acc_z = [NSNumber numberWithDouble:accelerometerData.acceleration.z];
                newItem.date = dateStr;
                newItem.mark_flag = tempFlag;

                newItem.gyro_x = [NSNumber numberWithDouble:gyro_x];
                newItem.gyro_y = [NSNumber numberWithDouble:gyro_y];
                newItem.gyro_z = [NSNumber numberWithDouble:gyro_z];
                
                newItem.quat_w = [NSNumber numberWithDouble:quat_w];
                newItem.quat_x = [NSNumber numberWithDouble:quat_x];
                newItem.quat_y = [NSNumber numberWithDouble:quat_y];
                newItem.quat_z = [NSNumber numberWithDouble:quat_z];
                newItem.quat_date = quat_date;
            }
        }];
    }
    
    if ([mManager isGyroAvailable] == YES) {
        [mManager setGyroUpdateInterval:updateInterval];
        [mManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
                [weakSelf.graphViewGRYO addX:gyroData.rotationRate.x y:gyroData.rotationRate.y z:gyroData.rotationRate.z];
                [weakSelf setGryoLabelValueX:gyroData.rotationRate.x y:gyroData.rotationRate.y z:gyroData.rotationRate.z];
            
            gyro_x = gyroData.rotationRate.x;
            gyro_y = gyroData.rotationRate.y;
            gyro_z = gyroData.rotationRate.z;
        }];

    }
    
    if ([mManager isDeviceMotionAvailable] == YES) {
        [mManager setDeviceMotionUpdateInterval:updateInterval];
        [mManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            CMQuaternion quat = deviceMotion.attitude.quaternion;

            NSString *dateStr = [weakSelf toGetCurrentTimeToMiliSecondsStr];
            NSLog(@"device----date///%@",dateStr);
            quat_w = quat.w;
            quat_x = quat.x;
            quat_y = quat.y;
            quat_z = quat.z;
            quat_date = dateStr;
            
            weakSelf.w.text = [NSString stringWithFormat:@"%f",quat.w];
            weakSelf.x.text = [NSString stringWithFormat:@"%f",quat.x];
            weakSelf.y.text = [NSString stringWithFormat:@"%f",quat.y];
            weakSelf.z.text = [NSString stringWithFormat:@"%f",quat.z];
            
        }];
    }
    
    self.updateIntervalLabel.text = [NSString stringWithFormat:@"%d Hz", (int)recordingRateHz];
    
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
    timerOfRecord = [NSTimer timerBlocks_scheduledTimerWithTimerInteval:0.1
                                                                  block:^{
                                                                      ACCGraphViewController *strongSelf = weakSelf;
                                                                      timeOfSeconds = timeOfSeconds+0.1;
                                                                      strongSelf.timeOfRecord.text = [NSString stringWithFormat:@"%.1f S",timeOfSeconds];
                                                                        }repeats:YES];
}
- (void)stopTimer
{
    if (timerOfRecord != nil) {
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

- (IBAction)stateMark0:(UIButton *)sender {
    stateFlag = state0;
    self.stateFlag0Btn.enabled = NO;
    self.stateFlag1Btn.enabled = YES;
    self.stateFlag2Btn.enabled = YES;
    self.stateFlag3Btn.enabled = YES;
    self.stateFlag4Btn.enabled = YES;
}

- (IBAction)stateMark1:(UIButton *)sender {
    stateFlag = state1;
    self.stateFlag0Btn.enabled = YES;
    self.stateFlag1Btn.enabled = NO;
    self.stateFlag2Btn.enabled = YES;
    self.stateFlag3Btn.enabled = YES;
    self.stateFlag4Btn.enabled = YES;
}
- (IBAction)stateMark2:(UIButton *)sender {
    stateFlag = state2;
    self.stateFlag0Btn.enabled = YES;
    self.stateFlag1Btn.enabled = YES;
    self.stateFlag2Btn.enabled = NO;
    self.stateFlag3Btn.enabled = YES;
    self.stateFlag4Btn.enabled = YES;
}
- (IBAction)stateMark3:(UIButton *)sender {
    stateFlag = state3;
    self.stateFlag0Btn.enabled = YES;
    self.stateFlag1Btn.enabled = YES;
    self.stateFlag2Btn.enabled = YES;
    self.stateFlag3Btn.enabled = NO;
    self.stateFlag4Btn.enabled = YES;
}
- (IBAction)stateMark4:(UIButton *)sender {
    stateFlag = state4;
    self.stateFlag0Btn.enabled = YES;
    self.stateFlag1Btn.enabled = YES;
    self.stateFlag2Btn.enabled = YES;
    self.stateFlag3Btn.enabled = YES;
    self.stateFlag4Btn.enabled = NO;
}


- (IBAction)start:(UIButton *)sender {
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
    [self startRecord];//开始录制屏幕
}
- (IBAction)stop:(UIButton *)sender {
    self.startRecordBtn.enabled = YES;
    self.stopRecordBtn.enabled = NO;
    isRecord = NO;
    
    [self stopTimer];
    [self stopRecord];//结束录制屏幕
//    [self.cdh saveContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ACCitem"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSArray *fetchObjects = [self.cdh.managedObjectContext executeFetchRequest:request error:nil];
    
    NSOutputStream *stream = [[NSOutputStream alloc] initToMemory];
    CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:stream encoding:NSUTF8StringEncoding delimiter:NO];
    
    for (ACCitem *item in fetchObjects) {
        [writer writeLineOfFields:@[@"time:",item.date,@",",@"acc_x:",item.acc_x,@",",@"acc_y:",item.acc_y,@",",@"acc_z:",item.acc_z,@",",@"gyro_x:",item.gyro_x,@",",@"gyro_y:",item.gyro_y,@",",@"gyro_z:",item.gyro_z,@",",@"quat_date:",item.quat_date,@",",@"quat_w:",item.quat_w,@",",@"quat_x:",item.quat_x,@",",@"quat_y:",item.quat_y,@",",@"quat_z:",item.quat_z,@",",@"state:",item.mark_flag]];
        
//        NSDictionary *sensorDic = [NSDictionary dictionaryWithObjectsAndKeys:item.date,@"time",item.acc_x,@"acc_x",item.acc_y,@"acc_y",item.acc_z,@"acc_z",item.gyro_x,@"gyro_x",item.gyro_y,@"gyrp_y",item.gyro_z,@"gyro_z",item.quat_date,@"quat_date",item.quat_w,@"quat_w",item.quat_x,@"quat_x",item.quat_y,@"quat_y",item.quat_z,@"quat_z",item.mark_flag,@"state",nil];
//        [writer writeLineWithDictionary:sensorDic];
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
    [_setRecordingRateBtn setTitle:@"set" forState:UIControlStateNormal];
    [_setRecordingRateBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    [_setRecordingRateBtn setBackgroundImage:[self imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateSelected];
    [_setRecordingRateBtn setTitle:@"done" forState:UIControlStateSelected];
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
#pragma mark - 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"视频录制完成.");
//    NSData *videodata = [[NSData alloc]initWithContentsOfURL:outputFileURL];
//    [videodata writeToFile:movFilePath atomically:YES];
}
#pragma mark - AVFoundation私有方法

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}
#pragma mark - ReplayKit方法

- (void)startRecord
{
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    if (!recorder.available) {
        NSLog(@"recorder is not available");
        return;
    }
    if (recorder.recording) {
        NSLog(@"it is recording");
        return;
    }
    [recorder startRecordingWithMicrophoneEnabled:YES handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"start recorder error - %@",error);
        }
    }];
}

- (void)stopRecord
{
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    if (!recorder.recording) {
        return;
    }
    [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        if (error) {
            NSLog(@"stop error - %@",error);
        }
        //录制结束弹出预览
        previewViewController.previewControllerDelegate = self;
        [self presentViewController:previewViewController animated:NO completion:^{
            NSLog(@"complition");
        }];
    }];
}

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    [previewController dismissViewControllerAnimated:YES completion:nil];
}

/* @abstract Called when the view controller is finished and returns a set of activity types that the user has completed on the recording. The built in activity types are listed in UIActivity.h. */
- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet <NSString *> *)activityTypes
{
    NSLog(@"activity - %@",activityTypes);
}
@end
