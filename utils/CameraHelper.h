//
//  CameraHelper.h
//  HoopsCam
//
//  Created by Hans on 10/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@import UIKit;

typedef enum :NSUInteger {
    VideoRecordStateUnkonw,
    VideoRecordStateRecording,
    VideoRecordStateResumeRecord,
    VideoRecordStatePausing,
    VideoRecordStateInteruped,
    VideoRecordStateStoped,
} VideoRecordState;

typedef enum :NSUInteger {
    CameraDeviceInputStateFront,
    CameraDeviceInputStateBack,
} CameraDeviceInputState;


@interface CameraHelper : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign) VideoRecordState videoRecordState;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (nonatomic, copy) void (^durationCallback)(NSTimeInterval duration);
@property (nonatomic, copy) void (^imageCallback)(UIImage *image);


- (void)configSession;
- (void)startSeesion;
- (void)stopSeesion;
- (void)changeCamera;

+ (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position;
+ (AVCaptureDeviceInput *)deviceInputWithDevice:(AVCaptureDevice *)device;
+ (CMSampleBufferRef)createOffsetSampleBufferWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withTimeOffset:(CMTime)timeOffset;

@end
