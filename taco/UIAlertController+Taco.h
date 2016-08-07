//
//  UIAlertController+Taco.h
//  taco
//
//  Created by Ian Meyer on 8/7/16.
//  Copyright © 2016 Ian Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Taco)

- (void)show;

+ (void)showAlertWithTitle:(NSString *)titleString message:(NSString *)messageString;

@end
