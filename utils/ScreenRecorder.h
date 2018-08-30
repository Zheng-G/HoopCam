//
//  ScreenRecorder.h
//  HoopsCam
//
//  Created by Hans on 12/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioRecorder.h"

@import UIKit;

typedef void(^VideoCompletionBlock)(NSString *videoPath);
typedef void (^ExportVideoCompletion)(NSString *exportVideoPath);
@protocol ScreenRecordDelegate;

@interface ScreenRecorder : NSObject
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, strong) UIView *recordView;

@property (nonatomic, weak) id <ScreenRecordDelegate> delegate;

@property (strong, nonatomic) NSURL *videoURL;
@property (nonatomic, readwrite) BOOL isPaused;
@property (nonatomic, readwrite) NSString *videoFileName;
@property (nonatomic, copy) void (^durationCallback)(NSTimeInterval duration);

+ (instancetype)sharedInstance;
- (BOOL) startRecording: (BOOL)is4K;
- (void) pauseRecording;
- (void) resumeRecording;
- (void)stopRecordingWithCompletion:(NSString*)fileName completion: (VideoCompletionBlock)completionBlock;
//- (void)setVideoFileName:(NSString *)newVideoFileName;
+ (void)mergeVideo:(NSString *)videoPath andAudio:(NSString *)audioPath withCompletion:(ExportVideoCompletion)completion;
@end

@protocol ScreenRecordDelegate <NSObject>
- (void)writeBackgroundFrameInContext:(CGContextRef*)contextRef;
@end
