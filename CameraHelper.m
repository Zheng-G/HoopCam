//
//  CameraHelper.m
//  HoopsCam
//
//  Created by Hans on 10/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import "CameraHelper.h"


@interface CameraHelper ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@implementation CameraHelper
{
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDeviceFront;
    AVCaptureDevice *_captureDeviceBack;
    AVCaptureDeviceInput *_captureDeviceInputFront;
    AVCaptureDeviceInput *_captureDeviceInputBack;
    CameraDeviceInputState _cameraDeviceInputState;
    
    AVCaptureVideoDataOutput *_captureVideoDataOutput;
    
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterInputPixelBufferAdaptor;
    
    
    CMTime _videoTimestamp;
    CMTime _startTimestamp;
    CMTime _timeOffset;
    BOOL _isSessionRuning;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static CameraHelper *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{
    NSLog(@"dealloc");
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer
{
    if (_captureVideoPreviewLayer == nil) {
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
        [_captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    return _captureVideoPreviewLayer;
}

- (void)configSession
{
    _videoTimestamp = kCMTimeInvalid;
    _timeOffset = kCMTimeInvalid;
    
    
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    _captureDeviceFront = [CameraHelper captureDeviceForPosition:AVCaptureDevicePositionFront];
    _captureDeviceBack = [CameraHelper captureDeviceForPosition:AVCaptureDevicePositionBack];
    
    _captureDeviceInputFront = [CameraHelper deviceInputWithDevice:_captureDeviceFront];
    _captureDeviceInputBack = [CameraHelper deviceInputWithDevice:_captureDeviceBack];
    
    
    if (_captureDeviceInputBack) {
        [_session addInput:_captureDeviceInputBack];
        _cameraDeviceInputState = CameraDeviceInputStateBack;
    }
    
    _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureVideoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    [_captureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if (_captureVideoDataOutput) {
        [_session addOutput:_captureVideoDataOutput];
    }
    
    
    AVCaptureConnection *conn = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [conn setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    
    [_session commitConfiguration];
    [self startSeesion];
}

- (void)changeCamera
{
    [_session beginConfiguration];
    if (_cameraDeviceInputState == CameraDeviceInputStateBack) {
        [_session removeInput:_captureDeviceInputBack];
        _session.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
        if ([_session canAddInput:_captureDeviceInputFront] == NO) {
            return;
        }
        
        _cameraDeviceInputState = CameraDeviceInputStateFront;
        [_session addInput:_captureDeviceInputFront];
        AVCaptureConnection *conn = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [conn setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        [conn setVideoMirrored:YES];
    }else {
        [_session removeInput:_captureDeviceInputFront];
        _session.sessionPreset = AVCaptureSessionPreset3840x2160; //AVCaptureSessionPresetHigh;
        if ([_session canAddInput:_captureDeviceInputBack] == NO) {
            return;
        }
        _cameraDeviceInputState = CameraDeviceInputStateBack;
        [_session addInput:_captureDeviceInputBack];
        AVCaptureConnection *conn = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [conn setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        [conn setVideoMirrored:NO];
    }
    [_session commitConfiguration];
}

- (void)startSeesion
{
    if (_isSessionRuning == YES) {
        return;
    }
    [_session startRunning];
    _isSessionRuning = YES;
}

- (void)stopSeesion
{
    _isSessionRuning = NO;
    [_session stopRunning];
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if( _videoRecordState == VideoRecordStateRecording && _assetWriter.status != AVAssetWriterStatusWriting  ){
            [_assetWriter startWriting];
            [_assetWriter startSessionAtSourceTime:lastSampleTime];
            _startTimestamp = lastSampleTime;
        }
        
        if (captureOutput == _captureVideoDataOutput){
            
            if (_videoRecordState == VideoRecordStateResumeRecord) {
                if (CMTIME_IS_VALID(lastSampleTime) && CMTIME_IS_VALID(_videoTimestamp)) {
                    CMTime offset = CMTimeSubtract(lastSampleTime, _videoTimestamp);
                    if (CMTIME_IS_INVALID(_timeOffset)) {
                        _timeOffset = offset;
                    }else {
                        _timeOffset = CMTimeAdd(_timeOffset, offset);
                    }
                }
                _videoRecordState = VideoRecordStateRecording;
            }
            
            if (_videoRecordState == VideoRecordStateInteruped) {
                
                _videoTimestamp = lastSampleTime;
                _videoRecordState = VideoRecordStatePausing;
            }
            
            if ( _assetWriter.status > AVAssetWriterStatusWriting ){
                if( _assetWriter.status == AVAssetWriterStatusFailed){
                    NSLog(@"Error: %@", _assetWriter.error);
                }
                return;
            }
            
            if (_videoRecordState == VideoRecordStateRecording && [_assetWriterInput isReadyForMoreMediaData]){
                // adjust the sample buffer if there is a time offset
                CMSampleBufferRef bufferToWrite = NULL;
                if (CMTIME_IS_VALID(_timeOffset)) {
                    bufferToWrite = [CameraHelper createOffsetSampleBufferWithSampleBuffer:sampleBuffer withTimeOffset:_timeOffset];
                    if (!bufferToWrite) {
                        NSLog(@"error subtracting the timeoffset from the sampleBuffer");
                    }
                } else {
                    bufferToWrite = sampleBuffer;
                    CFRetain(bufferToWrite);
                }
                if( ![_assetWriterInput appendSampleBuffer:bufferToWrite] ){
                    
                    NSLog(@"Unable to write to video input");
                }else {
                    CMTime offset = CMTimeSubtract(lastSampleTime, _startTimestamp);
                    NSLog(@"already write vidio %f",CMTimeGetSeconds(offset));
                    if (self.durationCallback) {
                        self.durationCallback(CMTimeGetSeconds(offset));
                    }
                }
                if (bufferToWrite) {
                    CFRelease(bufferToWrite);
                }
            }
        }
        [self imageFromSampleBuffer:sampleBuffer];

    }
    
}

- (void)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little
                                                 | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:quartzImage];

    CGImageRelease(quartzImage);
    
    if (self.imageCallback) {
        self.imageCallback(image);
    }
}

+ (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

+ (AVCaptureDeviceInput *)deviceInputWithDevice:(AVCaptureDevice *)device
{
    NSError *error = nil;
    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"error setting up front camera input (%@)", error);
    }
    return captureDeviceInput;
}

+ (CMSampleBufferRef)createOffsetSampleBufferWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withTimeOffset:(CMTime)timeOffset
{
    CMItemCount itemCount;
    
    OSStatus status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, NULL, &itemCount);
    if (status) {
        return NULL;
    }
    
    CMSampleTimingInfo *timingInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * (unsigned long)itemCount);
    if (!timingInfo) {
        return NULL;
    }
    
    status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, itemCount, timingInfo, &itemCount);
    if (status) {
        free(timingInfo);
        timingInfo = NULL;
        return NULL;
    }
    
    for (CMItemCount i = 0; i < itemCount; i++) {
        timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
        timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
    }
    
    CMSampleBufferRef offsetSampleBuffer;
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, itemCount, timingInfo, &offsetSampleBuffer);
    
    if (timingInfo) {
        free(timingInfo);
        timingInfo = NULL;
    }
    
    return offsetSampleBuffer;
}

@end
