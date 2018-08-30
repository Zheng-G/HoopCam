//
//  ScreenRecorder.m
//  HoopsCam
//
//  Created by Hans on 12/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import "ScreenRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ScreenRecorder()
@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property (strong, nonatomic) AVAssetWriterInput *videoWriterInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) NSDictionary *outputBufferPoolAuxAttributes;
//@property (strong, nonatomic) NSString *videoFileName;
@property (nonatomic) CFTimeInterval firstTimeStamp;
@property (nonatomic) CFTimeInterval elapsedTime;
@property (nonatomic) BOOL isRecording;
@property (nonatomic, strong) AudioRecorder *audioRecorder;
@property (nonatomic, strong) NSString *videoPath;
@end

@implementation ScreenRecorder
{
    dispatch_queue_t _render_queue;
    dispatch_queue_t _append_pixelBuffer_queue;
    dispatch_semaphore_t _frameRenderingSemaphore;
    dispatch_semaphore_t _pixelAppendSemaphore;
    
    CGSize _viewSize;
    CGFloat _scale;
    
    CGColorSpaceRef _rgbColorSpace;
    CVPixelBufferPoolRef _outputBufferPool;
}

#pragma mark - initializers

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static ScreenRecorder *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _viewSize = [UIApplication sharedApplication].delegate.window.bounds.size;
        _scale = [UIScreen mainScreen].scale;
        if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && _scale > 1) {
            _scale = 1.0;
        }
        _isRecording = NO;
        
        _append_pixelBuffer_queue = dispatch_queue_create("ASScreenRecorder.append_queue", DISPATCH_QUEUE_SERIAL);
        _render_queue = dispatch_queue_create("ASScreenRecorder.render_queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_render_queue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _frameRenderingSemaphore = dispatch_semaphore_create(1);
        _pixelAppendSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - public

- (void)setVideoURL:(NSURL *)videoURL
{
    NSAssert(!_isRecording, @"videoURL can not be changed whilst recording is in progress");
    _videoURL = videoURL;
}

- (BOOL) startRecording: (BOOL)is4K
{
    if (!_isRecording) {
        [self setUpWriter:is4K];
        _isRecording = (_videoWriter.status == AVAssetWriterStatusWriting);
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(writeVideoFrame)];
        _displayLink.preferredFramesPerSecond = 30;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [self.audioRecorder startRecord];
    }
    return _isRecording;
}

- (void) pauseRecording
{
    _isPaused = YES;
    [self.audioRecorder pauseRecord];
}

- (void) resumeRecording
{
    _isPaused = NO;
    [self.audioRecorder startRecord];
}

- (void)stopRecordingWithCompletion:(NSString*)fileName completion: (VideoCompletionBlock)completionBlock
{
    if (_isRecording) {
        [self.audioRecorder stopRecord];
        _isRecording = NO;
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [self completeRecordingSession: fileName completion:completionBlock];
    }
}
/*
- (void) setVideoFileName:(NSString *)newVideoFileName
{
    _videoFileName =  [[NSString alloc]initWithString:newVideoFileName];
    NSLog(@"File name is %@",_videoFileName);
}
*/

#pragma mark - private

-(void)setUpWriter:(BOOL)is4K
{
    _rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSDictionary *bufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                       (id)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                                       (id)kCVPixelBufferWidthKey : @(_viewSize.width * _scale),
                                       (id)kCVPixelBufferHeightKey : @(_viewSize.height * _scale),
                                       (id)kCVPixelBufferBytesPerRowAlignmentKey : @(_viewSize.width * _scale * 4)
                                       };
    
    _outputBufferPool = NULL;
    CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(bufferAttributes), &_outputBufferPool);
    
    
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    self.videoPath = [documents stringByAppendingPathComponent:@"video.mp4"];
    [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:self.videoPath];
    
    NSError* error = nil;
    _videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl
                                             fileType:AVFileTypeQuickTimeMovie
                                                error:&error];
    NSParameterAssert(_videoWriter);
    
    NSInteger pixelNumber = _viewSize.width * _viewSize.height * _scale;
    NSDictionary* videoCompression = @{AVVideoAverageBitRateKey: @(pixelNumber * 11.4)};
    
    NSDictionary* videoSettings = is4K ? @{AVVideoCodecKey: AVVideoCodecH264,
                                           AVVideoWidthKey: [NSNumber numberWithInt:_viewSize.width*_scale],
                                           AVVideoHeightKey: [NSNumber numberWithInt:_viewSize.height*_scale],
                                           AVVideoCompressionPropertiesKey: videoCompression}:
                                         @{
                                           AVVideoCodecKey: AVVideoCodecH264,
                                           AVVideoWidthKey: @1920,
                                           AVVideoHeightKey: @1080,
                                           AVVideoCompressionPropertiesKey: @{
                                              AVVideoAverageBitRateKey: @6000000,
                                              AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                                           }
                                          };
    
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(_videoWriterInput);
    
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    _videoWriterInput.transform = [self videoTransformForDeviceOrientation];
    
    _avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput sourcePixelBufferAttributes:nil];
    
    [_videoWriter addInput:_videoWriterInput];
    
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
}

- (CGAffineTransform)videoTransformForDeviceOrientation
{
    CGAffineTransform videoTransform;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationLandscapeLeft:
            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIDeviceOrientationLandscapeRight:
            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoTransform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            videoTransform = CGAffineTransformIdentity;
    }
    return videoTransform;
}

- (NSURL*)tempFileURL
{
    NSString *outputPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/screenCapture.mp4"];
    [self removeTempFilePath:outputPath];
    return [NSURL fileURLWithPath:outputPath];
}

- (void)removeTempFilePath:(NSString*)filePath
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError* error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }
}

- (void)completeRecordingSession:(NSString*)fileName completion:(VideoCompletionBlock)completionBlock;
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(_render_queue, ^{
        dispatch_sync(_append_pixelBuffer_queue, ^{
            
            [_videoWriterInput markAsFinished];
            [_videoWriter finishWritingWithCompletionHandler:^{
                
                if (self.videoURL) {

                } else {
                    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                    [ScreenRecorder mergeVideo:self.videoPath andAudio:self.audioRecorder.audioPath fileName: fileName withCompletion:^(NSString *exportVideoPath) {
                        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:exportVideoPath] completionBlock:^(NSURL *assetURL, NSError *error) {
                            if (error) {
                                NSLog(@"Error copying video to camera roll:%@", [error localizedDescription]);
                            } else {
                                completionBlock(exportVideoPath);
                                [weakSelf cleanup];
                            }
                        }];
                    }];
                }
            }];
        });
    });
}

- (void)cleanup
{
    self.avAdaptor = nil;
    self.videoWriterInput = nil;
    self.videoWriter = nil;
    self.firstTimeStamp = 0;
    self.elapsedTime = 0;
    self.outputBufferPoolAuxAttributes = nil;
    CGColorSpaceRelease(_rgbColorSpace);
    CVPixelBufferPoolRelease(_outputBufferPool);
}

- (void)writeVideoFrame
{
    
    if (!self.firstTimeStamp) {
        self.firstTimeStamp = _displayLink.timestamp;
    }
    CFTimeInterval offset = _displayLink.timestamp - self.firstTimeStamp;
    self.firstTimeStamp = _displayLink.timestamp;
    
    if(!_isPaused)
    {
        _elapsedTime += offset;
        [self createVideoFrame];
    }
}

- (void) createVideoFrame
{
    if (dispatch_semaphore_wait(_frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
    dispatch_async(_render_queue, ^{
        if (![_videoWriterInput isReadyForMoreMediaData]) return;
        CMTime time = CMTimeMakeWithSeconds(_elapsedTime, 1000);
        
        
        CVPixelBufferRef pixelBuffer = NULL;
        CGContextRef bitmapContext = [self createPixelBufferAndBitmapContext:&pixelBuffer];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self.durationCallback) {
                self.durationCallback(_elapsedTime);
            }
            UIGraphicsPushContext(bitmapContext);
            [self.recordView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIGraphicsPopContext();
        });
        
        if (dispatch_semaphore_wait(_pixelAppendSemaphore, DISPATCH_TIME_NOW) == 0) {
            dispatch_async(_append_pixelBuffer_queue, ^{
                BOOL success = [_avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                if (!success) {
                    NSLog(@"Warning: Unable to write buffer to video");
                }
                CGContextRelease(bitmapContext);
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                CVPixelBufferRelease(pixelBuffer);
                
                dispatch_semaphore_signal(_pixelAppendSemaphore);
            });
        } else {
            CGContextRelease(bitmapContext);
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            CVPixelBufferRelease(pixelBuffer);
        }
        
        dispatch_semaphore_signal(_frameRenderingSemaphore);
    });
}

- (CGContextRef)createPixelBufferAndBitmapContext:(CVPixelBufferRef *)pixelBuffer
{
    CVPixelBufferPoolCreatePixelBuffer(NULL, _outputBufferPool, pixelBuffer);
    CVPixelBufferLockBaseAddress(*pixelBuffer, 0);
    
    CGContextRef bitmapContext = NULL;
    bitmapContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(*pixelBuffer),
                                          CVPixelBufferGetWidth(*pixelBuffer),
                                          CVPixelBufferGetHeight(*pixelBuffer),
                                          8, CVPixelBufferGetBytesPerRow(*pixelBuffer), _rgbColorSpace,
                                          kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
                                          );
    CGContextScaleCTM(bitmapContext, _scale, _scale);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, _viewSize.height);
    CGContextConcatCTM(bitmapContext, flipVertical);
    
    return bitmapContext;
}

- (AudioRecorder *)audioRecorder {
    if (!_audioRecorder) {
        _audioRecorder = [AudioRecorder new];
    }
    
    return _audioRecorder;
}

+ (void)mergeVideo:(NSString *)videoPath andAudio:(NSString *)audioPath fileName:(NSString*)fileName withCompletion:(ExportVideoCompletion)completion {
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *outputPath = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", fileName]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:outputPath]) {
        if (![fm removeItemAtPath:outputPath error:nil]) {
            NSLog(@"remove old output file failed.");
        }
    }
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    
    CMTime startTime = kCMTimeZero;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);

    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *videoAssetTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:startTime error:nil];
    
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
    
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *audioAssetTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:startTime error:nil];
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    
    assetExport.outputURL = outputURL;
    
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        if ([fm fileExistsAtPath:videoPath]) {
            if (![fm removeItemAtPath:videoPath error:nil]) {
                NSLog(@"removing video file failed");
            }
        }
        
        if ([fm fileExistsAtPath:audioPath]) {
            if (![fm removeItemAtPath:audioPath error:nil]) {
                NSLog(@"removing audio file failed");
            }
        }
        
        if (completion) {
            completion(outputPath);
        }
    }];
}

@end
