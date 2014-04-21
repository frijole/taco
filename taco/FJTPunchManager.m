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

static NSMutableArray *_punches = nil;
static CLPlacemark *_workLocationPlacemark = nil;
static CLLocationManager *_locationManager = nil;
static FJTPunchManager *_locationManagerDelegate = nil; // :{

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
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.punchDate forKey:@"punchDate"];
    [encoder encodeInteger:self.punchType forKey:@"punchType"];
    [encoder encodeBool:self.archived forKey:@"archived"];
}

@end


@interface FJTPunchManager () <CLLocationManagerDelegate>

+ (CLLocationManager *)locationManager;
+ (FJTPunchManager *)locationManagerDelegate;

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
    // make a new icepack
    FJTPunch *rtnPunch = [[FJTPunch alloc] init];
    
    [rtnPunch setPunchDate:[NSDate date]];
    [rtnPunch setPunchType:FJTPunchTypePunchIn];
    
    // add it to the array
    [[[self class] punches] addObject:rtnPunch];
    
#ifdef LOGGING_ENABLED
    // make sure we made a copy, and it is in the array
    if ( rtnPunch &&
        [[[self class] punches] indexOfObject:rtnPunch] != NSNotFound )
        NSLog(@"✅ added punch in: %@", rtnPunch);
    else
        NSLog(@"⚠️ error adding punch in: %@", rtnPunch);
#endif
    
    // save!
    [self saveData];
    
    // schedule some notifications (if necessary)
    [[self class] scheduleNotificationsForPunch:rtnPunch];
    
    // and return it
    return rtnPunch;
}

+ (FJTPunch *)punchOut
{
    // make a new icepack
    FJTPunch *rtnPunch = [[FJTPunch alloc] init];
    
    [rtnPunch setPunchDate:[NSDate date]];
    [rtnPunch setPunchType:FJTPunchTypePunchOut];
    
    // add it to the array
    [[[self class] punches] addObject:rtnPunch];
    
#ifdef LOGGING_ENABLED
    // make sure we made a copy, and it is in the array
    if ( rtnPunch &&
        [[[self class] punches] indexOfObject:rtnPunch] != NSNotFound )
        NSLog(@"✅ added punch out: %@", rtnPunch);
    else
        NSLog(@"⚠️ error adding punch out: %@", rtnPunch);
#endif
    
    // save!
    [[self class] saveData];
    
    // cancel any scheduled notifications
    [[self class] cancelAllNotifications];
    
    // and return it
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
    
    // TODO: update region monitoring status (enable/update/disable)
    [self updateRegionMonitoringForPlacemark];
}


+ (BOOL)punchInReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"punchInReminder"];
}

+ (void)setPunchInReminderEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"punchInReminder"];
    [self updateRegionMonitoringForPlacemark];
}


+ (BOOL)punchOutReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"punchOutReminder"];
}

+ (void)setPunchOutReminderEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"punchOutReminder"];
    [self updateRegionMonitoringForPlacemark];
}


#pragma mark - Utilities

+ (CLLocationManager *)locationManager
{
    if ( !_locationManager ) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = [self locationManagerDelegate];
    }
    
    return _locationManager;
}

+ (FJTPunchManager *)locationManagerDelegate
{
    if ( !_locationManagerDelegate ) {
        _locationManagerDelegate = [[FJTPunchManager alloc] init];
    }
    
    return _locationManagerDelegate;
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"didExitRegion: %@", region);
    
    if ( [[self class] punchInReminderEnabled] ) {
        switch ( [[UIApplication sharedApplication] applicationState] ) {
            case UIApplicationStateActive:
                // show an alert
            {
                UIAlertView *tmpAlert = [[UIAlertView alloc] initWithTitle:@"taco" message:@"You arrived at work" delegate:nil cancelButtonTitle:@"Punch In" otherButtonTitles:nil];
                [tmpAlert show];
            }
                break;
            case UIApplicationStateBackground:
            case UIApplicationStateInactive:
                // local notificaiton
            {
                UILocalNotification *tmpLocalNotification = [[UILocalNotification alloc] init];
                tmpLocalNotification.alertBody = @"You arrived at work";
                tmpLocalNotification.alertAction = @"Punch In";
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
                // show an alert
            {
                UIAlertView *tmpAlert = [[UIAlertView alloc] initWithTitle:@"taco" message:@"You left work" delegate:nil cancelButtonTitle:@"Punch Out" otherButtonTitles:nil];
                [tmpAlert show];
            }
                break;
            case UIApplicationStateBackground:
            case UIApplicationStateInactive:
                // local notificaiton
            {
                UILocalNotification *tmpLocalNotification = [[UILocalNotification alloc] init];
                tmpLocalNotification.alertBody = @"You left work";
                tmpLocalNotification.alertAction = @"Punch Out";
                tmpLocalNotification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:tmpLocalNotification];
            }
                break;
        } // switch
    } // punchOutReminderEnabled
}

+ (void)updateRegionMonitoringForPlacemark
{
    // if we have a work location, and reminders that need it...
    if ( _workLocationPlacemark && ( [[self class] punchInReminderEnabled] || [[self class] punchOutReminderEnabled] ) ) {
        // can we get region-based location updates?
        if ( [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] ) {
            // but is background refresh available to get them?
            if ( [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable ) {
                // we can monitor for regions and will fire in the background

                // clear out any existing monitoring
                NSSet *tmpRegions = [[self locationManager] monitoredRegions];
                for ( CLRegion *tmpRegion in tmpRegions ) {
                    [[self locationManager] stopMonitoringForRegion:tmpRegion];
                }

                // and set up a region for the _workLocationPlacemark
                CLCircularRegion *tmpRegion = [[CLCircularRegion alloc] initWithCenter:_workLocationPlacemark.location.coordinate radius:50.0 identifier:@"workLocation"];
                [[self locationManager] startMonitoringForRegion:tmpRegion];
                // NSLog(@"Started monitoring for region: %@", tmpRegion);
                
            } /* else {
                NSLog(@"Background Refresh is not currently available.");
            } */
            
        } /* else {
            NSLog(@"Location Monitoring is not available for CLCirculatRegions");
        } */
    } else {
        // no placemark, or no reminders. make sure we're not monitoring
        NSSet *tmpRegions = [[self locationManager] monitoredRegions];
        for ( CLRegion *tmpRegion in tmpRegions ) {
            [[self locationManager] stopMonitoringForRegion:tmpRegion];
        }
        if ( [[self locationManager] monitoredRegions].count == 0 ) {
            // get rid of the location manager and its delegate (what if its still running?)
            _locationManager = nil;
            _locationManagerDelegate = nil;

            // NSLog(@"Stopped monitoring regions.");
        } /* else {
            NSLog(@"Attempted to stop monitoring regions, still monitoring: %@", [[self locationManager] monitoredRegions]);
        } */
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
        if ( tmpError ) {
            NSLog(@"eror deleting work location: %@", tmpError);
        }
    }
    
#ifdef LOGGING_ENABLED
    if ( tmpPunchSaveStatus ) {
        NSLog(@"✅ saved punches to disk");
    } else {
        NSLog(@"⚠️ error saving punches to disk");
    }

    if ( tmpLocationSaveStatus ) {
        NSLog(@"✅ saved work location to disk");
    } else {
        NSLog(@"⚠️ error saving work location to disk");
    }
#endif
    
}

+ (void)cancelAllNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
#ifdef LOGGING_ENABLED
    if ( [[UIApplication sharedApplication] scheduledLocalNotifications].count == 0 ) {
        NSLog(@"✅ all local notifications cancelled");
    } else {
        NSLog(@"⚠️ local notifications not cancelled: %@", [[UIApplication sharedApplication] scheduledLocalNotifications]);
    }
#endif
}

+ (void)scheduleNotificationsForPunch:(FJTPunch *)punch
{
    if ( punch.punchType == FJTPunchTypePunchIn ) {
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"lunchReminder"] ) {
            UILocalNotification *tmpLunchNotification = [[UILocalNotification alloc] init];
            [tmpLunchNotification setAlertBody:@"It's been four hours since you punched in."];
            [tmpLunchNotification setAlertAction:@"punch out"];
            NSDate *tmpFireDate = [NSDate dateWithTimeIntervalSinceNow:(4*60*60)];
            [tmpLunchNotification setFireDate:tmpFireDate];
            [[UIApplication sharedApplication] scheduleLocalNotification:tmpLunchNotification];
#ifdef LOGGING_ENABLED
            if ( [[[UIApplication sharedApplication] scheduledLocalNotifications] indexOfObject:tmpLunchNotification] != NSNotFound ) {
                NSLog(@"✅ scheduled lunch reminder at: %@", tmpLunchNotification.fireDate);
            } else {
                NSLog(@"⚠️ error scheduling lunch reminder");
            }
#endif
        }
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"shiftReminder"] ) {
            UILocalNotification *tmpShiftNotification = [[UILocalNotification alloc] init];
            [tmpShiftNotification setAlertBody:@"It's been eight hours since you punched in."];
            [tmpShiftNotification setAlertAction:@"punch out"];
            NSDate *tmpFireDate = [NSDate dateWithTimeIntervalSinceNow:(8*60*60)];
            [tmpShiftNotification setFireDate:tmpFireDate];
            [[UIApplication sharedApplication] scheduleLocalNotification:tmpShiftNotification];
#ifdef LOGGING_ENABLED
            if ( [[[UIApplication sharedApplication] scheduledLocalNotifications] indexOfObject:tmpShiftNotification] != NSNotFound ) {
                NSLog(@"✅ scheduled shift reminder at: %@", tmpShiftNotification.fireDate);
            } else {
                NSLog(@"⚠️ error scheduling shift reminder");
            }
#endif
        }
    }
}


@end
