//
//  FJTPunchManager.h
//  Icepack
//
//  Created by Ian Meyer on 2/8/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM( NSInteger, FJTPunchType) {
    FJTPunchTypeUnset = 0,
    FJTPunchTypePunchIn,
    FJTPunchTypePunchOut,
};


@interface FJTPunch : NSObject <NSCoding>

@property (nonatomic, readonly)     NSDate          *punchDate;
@property (nonatomic)               FJTPunchType    punchType;

@end


@interface FJTPunchManager : NSObject

// get the icepacks
+ (NSMutableArray *)punches;

+ (FJTPunch *)punchIn;
+ (FJTPunch *)punchOut;

// remove a specified icepack
+ (BOOL)deletePunch:(FJTPunch *)icepack;

@end
