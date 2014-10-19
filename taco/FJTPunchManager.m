//
//  FRTPunchManager.m
//  Icepack
//
//  Created by Ian Meyer on 2/8/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#define LOGGING_ENABLED YES

#define kFRTPunchManagerPunchFileName @"punches"
#define kFRTPunchManagerLocationFileName @"workLocation"

#import "FJTPunchManager.h"
#import "FJTLocationManager.h"

static NSMutableArray *_punches = nil;
static CLPlacemark *_workLocationPlacemark = nil;

NSString * const kFJTPunchManagerNotificationPunchInAction = @"Punch In";
NSString * const kFJTPunchManagerNotificationPunchOutAction = @"Punch Out";

@interface FJTPunch ()

@property (nonatomic, strong)   NSString    *title;
@property (nonatomic, strong)   NSDate      *punchDate;

@end

@implementation FJTPunch

#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)decoder
{
    if ( self = [super init] ) {
        // custom init
        self.punchDate = [decoder decodeObjectForKey:@"punchDate"];
        self.punchType = [decoder decodeIntegerForKey:@"punchType"];
        self.archived = [decoder decodeBoolForKey:@"archived"];
        self.punchNotes = [decoder decodeObjectForKey:@"punchNotes"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.punchDate forKey:@"punchDate"];
    [encoder encodeInteger:self.punchType forKey:@"punchType"];
    [encoder encodeBool:self.archived forKey:@"archived"];
    [encoder encodeObject:self.punchNotes forKey:@"punchNotes"];
}

@end


@implementation FJTPunchManager

#pragma mark - Punches

+ (NSMutableArray *)punches
{
    // see if we need to try and load
    if ( !_punches ) {
        [self loadData];
    }
    
    return _punches;
}

+ (FJTPunch *)punchIn
{
    FJTPunch *rtnPunch = [[FJTPunch alloc] init];
    
    [rtnPunch setPunchDate:[NSDate date]];
    [rtnPunch setPunchType:FJTPunchTypePunchIn];
    
    [[[self class] punches] addObject:rtnPunch];
    
#ifdef LOGGING_ENABLED
    if ( rtnPunch &&
        [[[self class] punches] indexOfObject:rtnPunch] != NSNotFound ) {
        NSLog(@"✅ added punch in: %@", rtnPunch);
    } else {
        NSLog(@"⚠️ error adding punch in: %@", rtnPunch);
    }
#endif
    
    [self saveData];
    
    [[self class] scheduleNotificationsForPunch:rtnPunch];
    
    return rtnPunch;
}

+ (FJTPunch *)punchOut
{
    FJTPunch *rtnPunch = [[FJTPunch alloc] init];
    
    [rtnPunch setPunchDate:[NSDate date]];
    [rtnPunch setPunchType:FJTPunchTypePunchOut];
    
    [[[self class] punches] addObject:rtnPunch];
    
#ifdef LOGGING_ENABLED
    if ( rtnPunch &&
        [[[self class] punches] indexOfObject:rtnPunch] != NSNotFound ) {
        NSLog(@"✅ added punch out: %@", rtnPunch);
    } else {
        NSLog(@"⚠️ error adding punch out: %@", rtnPunch);
    }
#endif
    
    [[self class] saveData];
    
    [[self class] cancelAllNotifications];
    
    return rtnPunch;
}

+ (BOOL)deletePunch:(FJTPunch *)punch
{
    // if the punch being deleted is the last one...
    if ( punch == [[[self class] punches] lastObject] ) {
        // and is a punch in or a punch out...
        if ( punch.punchType == FJTPunchTypePunchIn ) {
            // cancel any notifications it generated
            [[self class] cancelAllNotifications];
        } else if ( punch.punchType == FJTPunchTypePunchOut && [[self class] punches].count > 1 ) {
            // if there is a preceeding punch, schedule notifications if necessary
            FJTPunch *tmpNewLastPunch = [[[self class] punches] objectAtIndex:[[[self class] punches] indexOfObject:punch]-1];
            [[self class] scheduleNotificationsForPunch:tmpNewLastPunch];
        }
    }

    [[[self class] punches] removeObject:punch];
    
    BOOL rtnStatus = [[[self class] punches] indexOfObject:punch] == NSNotFound;
    
#ifdef LOGGING_ENABLED
    if ( rtnStatus )
        NSLog(@"✅ deleted punch: %@", punch);
    else
        NSLog(@"⚠️ error deleting punch: %@", punch);
#endif
    
    // if we worked, save changes
    if ( rtnStatus )
        [self saveData];
    
    // and let the caller know if we succeeded or not
    return rtnStatus;
}


#pragma mark - Reminders


// time-based reminders
+ (BOOL)lunchReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"lunchReminder"];
}

+ (void)setLunchReminderEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"lunchReminder"];
}


+ (BOOL)shiftReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftReminder"];
}

+ (void)setShiftReminderEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"shiftReminder"];
}


// location-based ones
+ (CLPlacemark *)workLocationPlacemark
{
    if ( !_workLocationPlacemark ) {
        // load it
        [self loadData];
    }
    
    return _workLocationPlacemark;
}

+ (void)setWorkLocationPlacemark:(CLPlacemark *)placemark
{
    _workLocationPlacemark = placemark;
    
    [self saveData];
    
    [self updateRegionMonitoring];
}


+ (BOOL)punchInReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"punchInReminder"];
}

+ (void)setPunchInReminderEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"punchInReminder"];
    [self updateRegionMonitoring];
}


+ (BOOL)punchOutReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"punchOutReminder"];
}

+ (void)setPunchOutReminderEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"punchOutReminder"];
    [self updateRegionMonitoring];
}


#pragma mark - Utilities
+ (void)updateRegionMonitoring
{
    // if we have a work location, and reminders that need it...
    if ( [[self class] workLocationPlacemark] && ( [[self class] punchInReminderEnabled] || [[self class] punchOutReminderEnabled] ) ) {
        // can we get region-based location updates?
        if ( [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] ) {
            // but is background refresh available to get them?
            if ( [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable ) {
                // we can monitor for regions and will fire in the background

                // clear out any existing monitoring
                NSSet *tmpRegions = [[FJTLocationManager defaultManager] monitoredRegions];
                for ( CLRegion *tmpRegion in tmpRegions ) {
                    [[FJTLocationManager defaultManager] stopMonitoringForRegion:tmpRegion];
                }

                // and set up a region for the _workLocationPlacemark
                CLCircularRegion *tmpRegion = [[CLCircularRegion alloc] initWithCenter:_workLocationPlacemark.location.coordinate radius:50.0 identifier:@"workLocation"];
                [[FJTLocationManager defaultManager] startMonitoringForRegion:tmpRegion];
                NSLog(@"✅ Started monitoring for region: %@", tmpRegion);
            } else {
                NSLog(@"⛔️ Background Refresh is not currently available.");
            }
            
        } else {
            NSLog(@"⛔️ Location Monitoring is not available for CLCirculatRegions");
        }
    } else {
        // no placemark, or no reminders. make sure we're not monitoring
        NSSet *tmpRegions = [[FJTLocationManager defaultManager] monitoredRegions];
        for ( CLRegion *tmpRegion in tmpRegions ) {
            [[FJTLocationManager defaultManager] stopMonitoringForRegion:tmpRegion];
        }
        if ( [[FJTLocationManager defaultManager] monitoredRegions].count == 0 ) {
            // get rid of the location manager and its delegate (what if its still running?)
            NSLog(@"✅ Stopped monitoring regions.");
        } else {
            NSLog(@"⛔️ Attempted to stop monitoring regions, still monitoring: %@", [[FJTLocationManager defaultManager] monitoredRegions]);
        }
    }
}

+ (void)loadData
{
    // try to load from disk
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *tmpPunchesFilePath = [NSString stringWithFormat:@"%@/%@",[documentDirectories objectAtIndex:0],kFRTPunchManagerPunchFileName];
    NSString *tmpWorkLocationFilePath = [NSString stringWithFormat:@"%@/%@",[documentDirectories objectAtIndex:0],kFRTPunchManagerLocationFileName];
    
    NSArray *tmpPunchesFromDisk = [NSKeyedUnarchiver unarchiveObjectWithFile:tmpPunchesFilePath];
    if ( tmpPunchesFromDisk && tmpPunchesFromDisk.count > 0 ) {
        _punches = [NSMutableArray arrayWithArray:tmpPunchesFromDisk];
    }
    
    _workLocationPlacemark = [NSKeyedUnarchiver unarchiveObjectWithFile:tmpWorkLocationFilePath];
    
#ifdef LOGGING_ENABLED
    if ( _punches ) {
        NSLog(@"✅ loaded punches from disk");
    } else {
        NSLog(@"⚠️ loading punches from disk failed");
    }
    
    if ( _workLocationPlacemark ) {
        NSLog(@"✅ loaded work location from disk");
    } else {
        NSLog(@"⚠️ loading work location from disk failed");
    }
#endif
    
    // if we don't have _punches
    // or it isn't a mutable array
    // set it to an empty one
    if ( !_punches || ![_punches respondsToSelector:@selector(addObject:)] ) {
        _punches = [NSMutableArray array];
    }
    
    return;
}

+ (void)saveData
{
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *tmpPunchesFilePath = [NSString stringWithFormat:@"%@/%@",[documentsDirectories objectAtIndex:0],kFRTPunchManagerPunchFileName];
    NSString *tmpWorkLocationFilePath = [NSString stringWithFormat:@"%@/%@",[documentsDirectories objectAtIndex:0],kFRTPunchManagerLocationFileName];
    
    BOOL tmpPunchSaveStatus = [NSKeyedArchiver archiveRootObject:[[self class] punches] toFile:tmpPunchesFilePath];
    BOOL tmpLocationSaveStatus = NO;
    if ( _workLocationPlacemark ) {
        tmpLocationSaveStatus = [NSKeyedArchiver archiveRootObject:[[self class] workLocationPlacemark] toFile:tmpWorkLocationFilePath];
    } else {
        NSError *tmpError = nil;
        tmpLocationSaveStatus = [[NSFileManager defaultManager] removeItemAtPath:tmpWorkLocationFilePath error:&tmpError];
        // if ( tmpError ) {
        //     NSLog(@"eror deleting work location: %@", tmpError);
        // }
    }
    
#ifdef LOGGING_ENABLED
    if ( tmpPunchSaveStatus ) {
        NSLog(@"✅ saved punches to disk");
    } else {
        if ( [[self class] punches] ) {
            NSLog(@"⚠️ error saving punches to disk");
        }
    }

    if ( tmpLocationSaveStatus ) {
        NSLog(@"✅ saved work location to disk");
    } else {
        if ( [[self class] workLocationPlacemark] ) {
            NSLog(@"⚠️ error saving work location to disk");
        }
    }
#endif
    
}

+ (void)cancelAllNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
#ifdef LOGGING_ENABLED
    NSLog(@"✅ cancelled all notifications");
#endif
}

+ (void)scheduleNotificationsForPunch:(FJTPunch *)punch
{
    if ( punch.punchType == FJTPunchTypePunchIn ) {
        
        // check for notification permissions
        if ( ( [[NSUserDefaults standardUserDefaults] boolForKey:@"lunchReminder"]
              || [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftReminder"] )
            && ![[UIApplication sharedApplication] currentUserNotificationSettings] ) {
            if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
                [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:nil]];
#ifdef LOGGING_ENABLED
                NSLog(@"✅ registered for local notifications");
#endif
            }
        }
        
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"lunchReminder"] ) {
            UILocalNotification *tmpLunchNotification = [[UILocalNotification alloc] init];
            [tmpLunchNotification setAlertBody:@"It's been four hours since you punched in."];
            [tmpLunchNotification setAlertAction:kFJTPunchManagerNotificationPunchOutAction];
            NSDate *tmpFireDate = [NSDate dateWithTimeIntervalSinceNow:(4*60*60)];
            [tmpLunchNotification setFireDate:tmpFireDate];
            [[UIApplication sharedApplication] scheduleLocalNotification:tmpLunchNotification];
#ifdef LOGGING_ENABLED
            NSLog(@"✅ scheduled lunch reminder");
#endif
        }
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftReminder"] ) {
            UILocalNotification *tmpShiftNotification = [[UILocalNotification alloc] init];
            [tmpShiftNotification setAlertBody:@"It's been eight hours since you punched in."];
            [tmpShiftNotification setAlertAction:kFJTPunchManagerNotificationPunchOutAction];
            NSDate *tmpFireDate = [NSDate dateWithTimeIntervalSinceNow:(8*60*60)];
            [tmpShiftNotification setFireDate:tmpFireDate];
            [[UIApplication sharedApplication] scheduleLocalNotification:tmpShiftNotification];
#ifdef LOGGING_ENABLED
            NSLog(@"✅ scheduled shift reminder");
#endif
        }
    }
}


@end
