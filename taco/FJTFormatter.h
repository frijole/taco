//
//  FJTFormatter.h
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FJTLongTimeFormatter; // 6:35:14 PM
@class FJTShortTimeFormatter; // 6:35
@class FJTDateFormatter; // March 5

@interface FJTFormatter : NSObject

+ (FJTLongTimeFormatter *)longTimeFormatter;
+ (FJTShortTimeFormatter *)shortTimeFormatter;
+ (FJTDateFormatter *)dateFormatter;

@end


@interface FJTLongTimeFormatter : NSDateFormatter
@end

@interface FJTShortTimeFormatter : NSDateFormatter
@end

@interface FJTDateFormatter : NSDateFormatter
@end