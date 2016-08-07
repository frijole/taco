//
//  FJTTabBarController.m
//  taco
//
//  Created by Ian Meyer on 10/19/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTTabBarController.h"

@interface FJTTabBarController ()

@property (nonatomic, strong) UIImageView *animatedClockImageView;
@property (nonatomic, strong) UIImageView *animatedHistoryImageView;
@property (nonatomic, strong) UIImageView *animatedAlarmImageView;

@end

@implementation FJTTabBarController

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSLog(@"selected item #%@", @([self.tabBar.items indexOfObject:item]));
    // wut
}

- (void)animateClock
{
    // make sure others are stopped
    [self stopAnimatingHistory];
    [self stopAnimatingAlarm];
    
    // animate the clock
    // go
}

- (void)stopAnimatingClock
{
    
}

- (void)animateHistory
{
    // make sure others are stopped
    [self stopAnimatingClock];
    [self stopAnimatingAlarm];

    // start history
}

- (void)stopAnimatingHistory
{
    
}

- (void)animateAlarm
{
    // stop others
    [self stopAnimatingClock];
    [self stopAnimatingHistory];

    // animate alarm
    // now!
}

- (void)stopAnimatingAlarm
{
    
}

#pragma mark - Overrides
- (UIImageView *)animatedClockImageView
{
    if ( !_animatedClockImageView ) {
        //
    }
    
    return _animatedClockImageView;
}

- (UIImageView *)animatedHistoryImageView
{
    if ( !_animatedHistoryImageView ) {
        //
    }
    
    return _animatedHistoryImageView;
}

- (UIImageView *)animatedAlarmImageView
{
    if ( !_animatedAlarmImageView ) {
        //
    }
    
    return _animatedAlarmImageView;
}

@end
