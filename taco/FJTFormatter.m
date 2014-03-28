//
//  FJTFormatter.m
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTFormatter.h"

static FJTTimeFormatter *_timeFormatter;
static FJTDateFormatter *_dateFormatter;

static NSTimer *_releaseTimer = nil;


@implementation FJTFormatter

+ (FJTTimeFormatter *)timeFormatter
{
    if ( !_timeFormatter ) {
        _timeFormatter = [[FJTTimeFormatter alloc] init];
        [[self class] resetReleaseTimer];
    }
    return _timeFormatter;
}

+ (FJTDateFormatter *)dateFormatter
{
    if ( !_dateFormatter ) {
        _dateFormatter = [[FJTDateFormatter alloc] init];
        [[self class] resetReleaseTimer];
    }
    return _dateFormatter;
}

+ (void)resetReleaseTimer
{
    if ( _releaseTimer ) {
        [_releaseTimer invalidate];
        _releaseTimer = nil;
    }
    _releaseTimer = [NSTimer scheduledTimerWithTimeInterval:30.0f
                                                     target:self
                                                   selector:@selector(releaseCachedFormatters)
                                                   userInfo:nil
                                                    repeats:NO];
}

+ (void)releaseCachedFormatters
{
    // NSLog(@"releaseCachedFormatters called");
    
    _timeFormatter = nil;
    _dateFormatter = nil;
}

@end


@implementation FJTTimeFormatter

- (instancetype)init
{
    if ( self = [super init] ) {
        [self setTimeStyle:NSDateFormatterMediumStyle]; // “3:30:59 PM”
        [self setDateStyle:NSDateFormatterNoStyle];
    }
    return self;
}

@end


@implementation FJTDateFormatter

- (instancetype)init
{
    if ( self = [super init] ) {
        [self setTimeStyle:NSDateFormatterNoStyle];
        [self setDateStyle:NSDateFormatterShortStyle]; // “3/27/2014”
    }
    return self;
}

@end