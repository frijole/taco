//
//  FJTSettingsViewController.h
//  taco
//
//  Created by Ian Meyer on 3/29/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJTSettingsViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UISwitch *punchInReminderSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *punchOutReminderSwitch;

@property (nonatomic, weak) IBOutlet UISwitch *lunchReminderSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *shiftReminderSwitch;

- (IBAction)switchChanged:(id)sender;

@end

@interface FJTSettingsRootViewController : UINavigationController

@end