//
//  FRTPunchManager.m
//  Icepack
//
//  Created by Ian Meyer on 2/8/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#define LOGGING_ENABLED YES

#define kFRTPunchManagerFileName @"icepacks"

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

+ (NSMutableArray *)punches
{
    // see if we need to try and load
    if ( !_punches )
        [self loadData];
    
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
    [self saveData];
    
    // and return it
    return rtnPunch;
}

+ (BOOL)deletePunch:(FJTPunch *)punch
{
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
    
    // if we don't have _icepacks
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


@end
