//
//  AudioRecorder.m
//  HoopsCam
//
//  Created by Hans on 23/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioRecorder.h"

@interface AudioRecorder ()

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, copy) NSString *audioPath;

@end

@implementation AudioRecorder

#pragma mark - Recorder Operation
- (void)startRecord {
    if ([self.recorder prepareToRecord]) {
        [self.recorder record];
    }
}

- (void)pauseRecord {
    [self.recorder pause];
}

- (void)stopRecord {
    [self.recorder stop];
}

- (void)deleteRecord {
    [self.recorder deleteRecording];
}

#pragma mark - private method
- (void)configureAudioSession {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (NSURL *)wavFileURL {
    return [NSURL fileURLWithPath:self.audioPath];
}

+ (NSDictionary*)fetchAudioRecorderSettingDict {
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey,
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                   nil];
    return recordSetting;
}

#pragma mark - Getters
- (AVAudioRecorder *)recorder {
    if (!_recorder) {
        [self configureAudioSession];
        _recorder = [[AVAudioRecorder alloc] initWithURL:[self wavFileURL] settings:[self.class fetchAudioRecorderSettingDict] error:nil];
        _recorder.meteringEnabled = YES;
    }
    
    return _recorder;
}

- (NSString *)audioPath {
    if (!_audioPath) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        _audioPath = [docPath stringByAppendingPathComponent:@"sound.wav"];
    }
    
    return _audioPath;
}

@end
