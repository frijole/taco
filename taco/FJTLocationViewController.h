//
//  FJTLocationViewController.h
//  taco
//
//  Created by Ian Meyer on 3/30/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FJTLocationViewController;

@protocol FJTLocationViewControllerDelegate <NSObject>

- (void)locationViewController:(FJTLocationViewController *)viewController didSetPlacemark:(CLPlacemark *)placemark;

@end

@interface FJTLocationViewController : UIViewController

@property (nonatomic, strong) CLPlacemark *placemark;
@property (nonatomic, weak) NSObject <FJTLocationViewControllerDelegate> *delegate;

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark;

@end
