//
//  FJTFormatter.h
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FJTTimeFormatter; // 6:35 PM
@class FJTDateFormatter; // March 5

@interface FJTFormatter : NSObject

+ (FJTTimeFormatter *)timeFormatter;
+ (FJTDateFormatter *)dateFormatter;

@end


@interface FJTTimeFormatter : NSDateFormatter
@end

@interface FJTDateFormatter : NSDateFormatter
@end