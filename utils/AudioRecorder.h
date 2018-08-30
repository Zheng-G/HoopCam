//
//  AudioRecorder.h
//  HoopsCam
//
//  Created by Hans on 23/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioRecorder : NSObject

@property (nonatomic, copy, readonly) NSString *audioPath;

- (void)startRecord;
- (void)pauseRecord;
- (void)stopRecord;
- (void)deleteRecord;

@end
