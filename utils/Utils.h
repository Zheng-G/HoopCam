//
//  Utils.h
//  HoopsCam
//
//  Created by Hans on 23/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface Utils : NSObject
{
    MBProgressHUD *mbProgress;
}

- (id) init;
+ (Utils *)sharedObject;

- (void) showMBProgress:(UIView *)view message:(NSString *)message;
- (void) hideMBProgress;
+ (void)showSuccess:(NSString *)success toView:(UIView *)view afterDelay:(NSTimeInterval)delay;
+ (void)showToast:(NSString *)success toView:(UIView *)view afterDelay:(NSTimeInterval)delay;
+ (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view afterDelay:(NSTimeInterval)delay;
- (void) showAlert:(NSString *)title body:(NSString *)message;

- (void) setDefaultObject:(NSObject *)object forKey:(NSString *)key;
- (NSObject*) getDefaultObject:(NSString*)key;

@end

