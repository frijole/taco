//
//  NSDate+Taco.m
//  taco
//
//  Created by Ian Meyer on 4/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "NSDate+Taco.h"

@implementation NSDate (Taco)

- (NSDate *)dateAtBeginningOfDay
{
    // Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];
    
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    
    // Convert back
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];

    return beginningOfDay;
}

@end
