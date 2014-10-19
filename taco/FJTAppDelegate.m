//
//  FJTAppDelegate.m
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTAppDelegate.h"

@implementation FJTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // see if we were launched with a notification
    UILocalNotification *tmpNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if ( tmpNotification ) {
        NSLog(@"launched with notification: %@",tmpNotification);
        
        NSString *tmpAlertBody = tmpNotification.alertBody;
        NSString *tmpAlertAction = tmpNotification.alertAction;
        
        [MMAlertView showAlertViewWithTitle:nil
                                    message:tmpAlertBody
                          cancelButtonTitle:@"Close"
                          acceptButtonTitle:tmpAlertAction
                                cancelBlock:nil
                                acceptBlock:^{
                                    // do something
                                    if ( [tmpAlertAction isEqualToString:kFJTPunchManagerNotificationPunchOutAction] ) {
                                        [FJTPunchManager punchOut];
                                    } else if ( [tmpAlertAction isEqualToString:kFJTPunchManagerNotificationPunchInAction] ) {
                                        [FJTPunchManager punchIn];
                                    }
                                }];
    }
    
    // [self configureAppearance];
    
    // Check for location notifications?
    [FJTPunchManager updateRegionMonitoring];
        
    return YES;
}

- (void)configureAppearance
{
    [self.window setTintColor:[UIColor orangeColor]];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"notification settings updated: %@", notificationSettings);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"received local notication: %@", notification);
}

@end
