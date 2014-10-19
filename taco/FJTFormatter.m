//
//  FJTFormatter.m
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTFormatter.h"

static FJTLongTimeFormatter *_longTimeFormatter;
static FJTShortTimeFormatter *_shortTimeFormatter;
static FJTDateFormatter *_dateFormatter;

static NSTimer *_releaseTimer = nil;


@implementation FJTFormatter

+ (FJTLongTimeFormatter *)longTimeFormatter
{
    if ( !_longTimeFormatter ) {
        _longTimeFormatter = [[FJTLongTimeFormatter alloc] init];
        [[self class] resetReleaseTimer];
    }
    return _longTimeFormatter;
}

+ (FJTShortTimeFormatter *)shortTimeFormatter
{
    if ( !_shortTimeFormatter ) {
        _shortTimeFormatter = [[FJTShortTimeFormatter alloc] init];
        [[self class] resetReleaseTimer];
    }
    return _shortTimeFormatter;
}

+ (FJTDateFormatter *)dateFormatter
{
    if ( !_dateFormatter ) {
        _dateFormatter = [[FJTDateFormatter alloc] init];
        [_dateFormatter setDoesRelativeDateFormatting:YES];
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
    
    _longTimeFormatter = nil;
    _shortTimeFormatter = nil;
    _dateFormatter = nil;
}

@end


@implementation FJTLongTimeFormatter

- (instancetype)init
{
    if ( self = [super init] ) {
        [self setTimeStyle:NSDateFormatterMediumStyle]; // “3:30:59 PM”
        [self setDateStyle:NSDateFormatterNoStyle];
    }
    return self;
}

@end


@implementation FJTShortTimeFormatter

- (instancetype)init
{
    if ( self = [super init] ) {
        [self setTimeStyle:NSDateFormatterShortStyle]; // “3:30 PM”
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