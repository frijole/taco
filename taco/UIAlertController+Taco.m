//
//  UIAlertController+Taco.m
//  taco
//
//  Created by Ian Meyer on 8/7/16.
//  Copyright © 2016 Ian Meyer. All rights reserved.
//

#import "UIAlertController+Taco.h"
#import <objc/runtime.h>

// Q. "What was the best practice for displaying a UIAlertController?"
// A. "Internally Apple is creating a UIWindow with a transparent UIViewController and then presenting the UIAlertController on it"
// via http://stackoverflow.com/questions/26554894/how-to-present-uialertcontroller-when-not-in-a-view-controller/36540728#36540728

@interface UIAlertController (Private)

@property (nonatomic, strong) UIWindow *alertWindow;

@end

@implementation UIAlertController (Private)

@dynamic alertWindow;

- (void)setAlertWindow:(UIWindow *)alertWindow {
    objc_setAssociatedObject(self, @selector(alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow *)alertWindow {
    return objc_getAssociatedObject(self, @selector(alertWindow));
}

@end

@implementation UIAlertController (Taco)

+ (void)showAlertWithTitle:(NSString *)titleString message:(NSString *)messageString {
    UIAlertController *tmpAlert = [UIAlertController alertControllerWithTitle:titleString message:messageString preferredStyle:UIAlertControllerStyleAlert];
    [tmpAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [tmpAlert show];
}

- (void)show {
    void (^presentationBlock)() = ^(){
        self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.alertWindow.rootViewController = [[UIViewController alloc] init];
        
        // we inherit the main window's tintColor
        self.alertWindow.tintColor = [UIApplication sharedApplication].delegate.window.tintColor;
        // window level is above the top window (this makes the alert, if it's a sheet, show over the keyboard)
        UIWindow *topWindow = [UIApplication sharedApplication].windows.lastObject;
        self.alertWindow.windowLevel = topWindow.windowLevel + 1;
        
        [self.alertWindow makeKeyAndVisible];
        [self.alertWindow.rootViewController presentViewController:self animated:YES completion:nil];
    };
    
    if ( [NSThread isMainThread] ) {
        presentationBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), presentationBlock);
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // ensure the window gets destroyed
    self.alertWindow.hidden = YES;
    self.alertWindow = nil;
}

@end
