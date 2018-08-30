//
//  Utils.m
//  HoopsCam
//
//  Created by Hans on 23/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

#import "Utils.h"

@implementation Utils

-(id) init
{
    if((self = [super init]))
    {

    }
    return self;
}

+ (Utils *)sharedObject
{
    static Utils *objUtility = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        objUtility = [[Utils alloc] init];
    });
    return objUtility;
}

- (void) showMBProgress:(UIView *)view message:(NSString *)message
{
    mbProgress = [[MBProgressHUD alloc] initWithView:view];
    mbProgress.detailsLabel.text = message;
    [view addSubview:mbProgress];
    [mbProgress showAnimated:YES];
}

- (void) hideMBProgress
{
    if(mbProgress)
        [mbProgress hideAnimated:YES];
}

+ (void)showSuccess:(NSString *)success toView:(UIView *)view afterDelay:(NSTimeInterval)delay
{
    [self show:success icon:@"success" view:view afterDelay:delay];
}

+ (void)showToast:(NSString *)success toView:(UIView *)view afterDelay:(NSTimeInterval)delay
{
   [self show:success icon:@"" view:view afterDelay:delay];
}

+ (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view afterDelay:(NSTimeInterval)delay
{
    if (view == nil) view = [UIApplication sharedApplication].keyWindow;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = text;
    
    if(![icon isEqualToString:@""])
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:icon]];
    
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hideAnimated:YES afterDelay:delay];
}

- (void) showAlert:(NSString *)title body:(NSString *)message
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alertView.tag = 100;
    [alertView show];
}

- (void) setDefaultObject:(NSObject *)object forKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:object forKey:key];
    [defaults synchronize];
}

- (NSObject*) getDefaultObject:(NSString*)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

@end
