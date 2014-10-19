//
//  FJTLocationManager.m
//  taco
//
//  Created by Ian Meyer on 10/18/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTLocationManager.h"

static FJTLocationManager *_defaultManager = nil;

@interface FJTLocationManager () <CLLocationManagerDelegate>

@end

@implementation FJTLocationManager

+ (FJTLocationManager *)defaultManager {
    if ( !_defaultManager ) {
        _defaultManager = [[FJTLocationManager alloc] init];
        _defaultManager.delegate = _defaultManager;
    }
    return _defaultManager;
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"didEnterRegion: %@", region);
    
    if ( [[self class] punchInReminderEnabled] ) {
        switch ( [[UIApplication sharedApplication] applicationState] ) {
            case UIApplicationStateActive:
            {   // show an alert
                NSLog(@"application active");
                [MMAlertView showAlertViewWithTitle:nil
                                            message:@"You arrived at work"
                                  cancelButtonTitle:@"Close"
                                  acceptButtonTitle:kFJTPunchManagerNotificationPunchInAction
                                        cancelBlock:nil
                                        acceptBlock:^{
                                            [FJTPunchManager punchIn];
                                        }];
            }
                break;
            case UIApplicationStateBackground:
            case UIApplicationStateInactive:
            {   // local notificaiton
                NSLog(@"application in background or inactive");
                UILocalNotification *tmpLocalNotification = [[UILocalNotification alloc] init];
                tmpLocalNotification.alertBody = @"You arrived at work";
                tmpLocalNotification.alertAction = kFJTPunchManagerNotificationPunchInAction;
                tmpLocalNotification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:tmpLocalNotification];
            }
                break;
        } // switch
    } // punchInReminderEnabled
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"didExitRegion: %@", region);
    
    if ( [[self class] punchOutReminderEnabled] ) {
        switch ( [[UIApplication sharedApplication] applicationState] ) {
            case UIApplicationStateActive:
            {   // show an alert
                NSLog(@"application active");
                
                [MMAlertView showAlertViewWithTitle:nil
                                            message:@"You left work"
                                  cancelButtonTitle:@"Close"
                                  acceptButtonTitle:kFJTPunchManagerNotificationPunchOutAction
                                        cancelBlock:nil
                                        acceptBlock:^{
                                            [FJTPunchManager punchOut];
                                        }];
            }
                break;
            case UIApplicationStateBackground:
            case UIApplicationStateInactive:
            {   // local notificaiton
                NSLog(@"application in background or inactive");
                
                UILocalNotification *tmpLocalNotification = [[UILocalNotification alloc] init];
                tmpLocalNotification.alertBody = @"You left work";
                tmpLocalNotification.alertAction = kFJTPunchManagerNotificationPunchOutAction;
                tmpLocalNotification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:tmpLocalNotification];
            }
                break;
        } // switch
    } // punchOutReminderEnabled
}

@end
