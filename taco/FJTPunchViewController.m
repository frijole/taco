//
//  FJTFirstViewController.m
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTPunchViewController.h"

#import "FJTFormatter.h"

@interface FJTPunchViewController ()

@property (nonatomic, strong) NSTimer *timeDisplayTimer;

@end

@implementation FJTPunchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.punchButton.layer setCornerRadius:5.0f];
    [self.punchButton.layer setMasksToBounds:YES];
    
    // [self.tapGestureRecognizer requireGestureRecognizerToFail:self.longPressGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updatePunchLabel];
    
    [self setTimeDisplayTimer:[NSTimer scheduledTimerWithTimeInterval:0.05f
                                                               target:self
                                                             selector:@selector(updateTimeLabel)
                                                             userInfo:nil
                                                              repeats:YES]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.timeDisplayTimer invalidate];
}

- (void)updatePunchLabel
{
    NSString *tmpLastPunchText = @"No Punches Yet.";
    NSString *tmpButtonTitle = @"Punch In";
    FJTPunch *tmpPunch = [FJTPunchManager punches].lastObject;
    NSString *tmpPunchTypeString = tmpPunch.punchType==FJTPunchTypePunchOut?@"Out":@"In";

    if ( tmpPunch ) {
        tmpLastPunchText = [NSString stringWithFormat:@"Last Punch: %@\n%@ at %@",
                            tmpPunchTypeString,
                            [[FJTFormatter dateFormatter] stringFromDate:tmpPunch.punchDate],
                            [[FJTFormatter shortTimeFormatter] stringFromDate:tmpPunch.punchDate]];
    
        if ( tmpPunch.punchType == FJTPunchTypePunchIn ) {
            tmpButtonTitle = @"Punch Out";
        }
    }
    
    
    
    NSMutableAttributedString *tmpLastPunchMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:tmpLastPunchText
                                                                                                            attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Light" size:16.0f]}];
    
    if ( [tmpLastPunchText componentsSeparatedByString:@"\n"].count > 1 ) {
        [tmpLastPunchMutableAttributedString setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Light" size:18.0f]}
                                                     range:NSMakeRange(0, [tmpLastPunchText rangeOfString:@"\n"].location)];
    }
    
    [tmpLastPunchMutableAttributedString setAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Helvetica" size:18.0f]}
                                                 range:[tmpLastPunchText rangeOfString:tmpPunchTypeString]];
    

    [self.littleLabel setAttributedText:tmpLastPunchMutableAttributedString];
    
    // [self.littleLabel setText:tmpLastPunchText];
    [self.punchButton setTitle:tmpButtonTitle forState:UIControlStateNormal];
    [self.punchButton setTitle:tmpButtonTitle forState:UIControlStateDisabled];
}

- (void)updateTimeLabel
{
    [self.bigLabel setText:[[FJTFormatter longTimeFormatter] stringFromDate:[NSDate date]]];
}

- (IBAction)punchButtonPressed:(id)sender
{
    FJTPunch *tmpPunch = [FJTPunchManager punches].lastObject;
    if ( tmpPunch && tmpPunch.punchType == FJTPunchTypePunchIn ) {
        // punch out
        [FJTPunchManager punchOut];
    } else {
        // punch in
        [FJTPunchManager punchIn];
        
        // check for unset notifications
        if ( ![[NSUserDefaults standardUserDefaults] objectForKey:@"lunchReminder"]
            && ![[NSUserDefaults standardUserDefaults] objectForKey:@"shiftReminder"] ) {
            
            UIAlertController *tmpNotificationAlert = [UIAlertController alertControllerWithTitle:@"Enable Reminders?" message:@"Would you like to be remided to take a break when you have been at work for 4 hours, and to leave after 8?" preferredStyle:UIAlertControllerStyleAlert];
            [tmpNotificationAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                // set to NO
                [FJTPunchManager setLunchReminderEnabled:NO];
                [FJTPunchManager setShiftReminderEnabled:NO];
            }]];
            [tmpNotificationAlert addAction:[UIAlertAction actionWithTitle:@"Enable" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // set to YES
                [FJTPunchManager setLunchReminderEnabled:YES];
                [FJTPunchManager setShiftReminderEnabled:YES];
            }]];
            [self presentViewController:tmpNotificationAlert animated:YES completion:nil];
        }
    }
    
    [self updatePunchLabel];
}

- (IBAction)tapGestureRecognizerAction:(id)sender
{
    FJTPunch *tmpPunch = [FJTPunchManager punches].lastObject;
    if ( tmpPunch && tmpPunch.punchType == FJTPunchTypePunchIn ) {
        // punch out
        [FJTPunchManager punchOut];
    } else {
        // punch in
        [FJTPunchManager punchIn];
    }
    
    [self updatePunchLabel];
}

- (IBAction)longPressGestureRecognizerAction:(UILongPressGestureRecognizer *)sender
{
    if ( sender.state == UIGestureRecognizerStateBegan ) {
        UIAlertController *tmpAdvancedPunchSheet = [UIAlertController alertControllerWithTitle:nil
                                                                                       message:nil
                                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [tmpAdvancedPunchSheet addAction:[UIAlertAction actionWithTitle:@"Punch In"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   // punch in
                                                                   [FJTPunchManager punchIn];
                                                                   [self updatePunchLabel];
                                                               }]];
        
        [tmpAdvancedPunchSheet addAction:[UIAlertAction actionWithTitle:@"Punch Out"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   [FJTPunchManager punchOut];
                                                                   [self updatePunchLabel];
                                                               }]];
        
        [tmpAdvancedPunchSheet addAction:[UIAlertAction actionWithTitle:@"Delete Last Punch"
                                                                 style:UIAlertActionStyleDestructive
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   FJTPunch *tmpPunch = [[FJTPunchManager punches] lastObject];
                                                                   [FJTPunchManager deletePunch:tmpPunch];
                                                                   [self updatePunchLabel];
                                                               }]];
        
        [tmpAdvancedPunchSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                                 style:UIAlertActionStyleCancel
                                                                handler:nil]];
        
        [self presentViewController:tmpAdvancedPunchSheet animated:YES completion:nil];
    }
}

@end
