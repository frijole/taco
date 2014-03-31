//
//  FRTPunchManager.m
//  Icepack
//
//  Created by Ian Meyer on 2/8/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#define LOGGING_ENABLED YES

#define kFRTPunchManagerFileName @"punches"

#import "FJTPunchManager.h"

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
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.punchDate forKey:@"punchDate"];
    [encoder encodeInteger:self.punchType forKey:@"punchType"];
}

@end


@interface FJTPunchManager ()

+ (void)loadData;
+ (void)saveData;

@end

static NSMutableArray *_punches = nil;

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
    return nil;
}

+ (void)setWorkLocationPlacemark:(CLPlacemark *)placemark
{
    // TODO: save location (or clear if nil)
    // TODO: update region monitoring status (enable/update/disable)
}


+ (BOOL)punchInReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"punchInReminder"];
}

+ (void)setPunchInReminderEnabled:(BOOL)enabled
{
    // TODO: check for location before enabling
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"punchInReminder"];
    // TODO: disable region monitoring if necessary
}


+ (BOOL)punchOutReminderEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"punchOutReminder"];
}

+ (void)setPunchOutReminderEnabled:(BOOL)enabled
{
    // TODO: check for location before enabling
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"punchOutReminder"];
    // TODO: disable region monitoring if necessary
}


#pragma mark - Utilities

+ (void)loadData
{
    // try to load from disk
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tmpAddressFilePath = [NSString stringWithFormat:@"%@/%@",[documentDirectories objectAtIndex:0],kFRTPunchManagerFileName];
    NSArray *tmpIcepacksFromDisk = [NSKeyedUnarchiver unarchiveObjectWithFile:tmpAddressFilePath];
    if ( tmpIcepacksFromDisk && tmpIcepacksFromDisk.count > 0 )
        _punches = [NSMutableArray arrayWithArray:tmpIcepacksFromDisk];
    
#ifdef LOGGING_ENABLED
    if ( _punches )
        NSLog(@"✅ loaded punches from disk");
    else
        NSLog(@"⚠️ loading punches from disk failed");
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
    
    NSString *tmpAddressFilePath = [NSString stringWithFormat:@"%@/%@",[documentsDirectories objectAtIndex:0],kFRTPunchManagerFileName];
    
    BOOL saveStatus = [NSKeyedArchiver archiveRootObject:[[self class] punches] toFile:tmpAddressFilePath];
    
#ifdef LOGGING_ENABLED
    if ( saveStatus ) {
        NSLog(@"✅ saved punches to disk");
    } else {
        NSLog(@"⚠️ error saving punches to disk");
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
