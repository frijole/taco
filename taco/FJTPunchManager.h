//
//  FJTPunchManager.h
//  Icepack
//
//  Created by Ian Meyer on 2/8/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM( NSInteger, FJTPunchType) {
    FJTPunchTypeUnset = 0,
    FJTPunchTypePunchIn,
    FJTPunchTypePunchOut,
};

extern NSString * const kFJTPunchManagerNotificationPunchInAction;
extern NSString * const kFJTPunchManagerNotificationPunchOutAction;

@interface FJTPunch : NSObject <NSCoding>

@property (nonatomic, readonly)     NSDate          *punchDate;
@property (nonatomic)               FJTPunchType    punchType;

@property (nonatomic, strong)       NSString        *punchNotes;

@property (nonatomic)               BOOL            archived;

@end


@interface FJTPunchManager : NSObject

// punches
+ (NSMutableArray *)punches;

+ (FJTPunch *)punchIn;
+ (FJTPunch *)punchOut;

+ (BOOL)deletePunch:(FJTPunch *)icepack;

+ (void)saveData;

// time-based reminders
+ (BOOL)lunchReminderEnabled;
+ (void)setLunchReminderEnabled:(BOOL)enabled;

+ (BOOL)shiftReminderEnabled;
+ (void)setShiftReminderEnabled:(BOOL)enabled;

// location-based ones
+ (CLPlacemark *)workLocationPlacemark;
+ (void)setWorkLocationPlacemark:(CLPlacemark *)placemark;

+ (BOOL)punchInReminderEnabled;
+ (void)setPunchInReminderEnabled:(BOOL)enabled;

+ (BOOL)punchOutReminderEnabled;
+ (void)setPunchOutReminderEnabled:(BOOL)enabled;

+ (void)updateRegionMonitoring;

@end