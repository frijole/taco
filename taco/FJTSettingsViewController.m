//
//  FJTSettingsViewController.m
//  taco
//
//  Created by Ian Meyer on 3/29/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTSettingsViewController.h"

#if LOCATION_ENABLED
#import "FJTLocationViewController.h"
#endif

typedef NS_ENUM( NSInteger, FJTSettingsTableViewSection ) {
//    FJTSettingsTableViewSectionLocation = 0,
    FJTSettingsTableViewSectionReminders = 0,
    FJTSettingsTableViewSectionClearButton,
    
    FJTSettingsTableViewSectionCount
};

@interface FJTSettingsViewController () /* <FJTLocationViewControllerDelegate> */

@end

@implementation FJTSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:nil action:nil]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)switchChanged:(UISwitch *)sender
{
    if ( sender == self.lunchReminderSwitch ) {
        [FJTPunchManager setLunchReminderEnabled:sender.isOn];
    } else if ( sender == self.shiftReminderSwitch ) {
        [FJTPunchManager setShiftReminderEnabled:sender.isOn];
    }
#if LOCATION_ENABLED
    else if ( sender == self.punchInReminderSwitch ) {
        [FJTPunchManager setPunchInReminderEnabled:sender.isOn];
    } else if ( sender == self.punchOutReminderSwitch ) {
        [FJTPunchManager setPunchOutReminderEnabled:sender.isOn];
    }
#endif
}

#if LOCATION_ENABLED
- (void)locationViewController:(FJTLocationViewController *)viewController didSetPlacemark:(CLPlacemark *)placemark
{
    [FJTPunchManager setWorkLocationPlacemark:placemark];
    
    [self.navigationController popViewControllerAnimated:YES];
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *rtnCell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if ( indexPath.section == FJTSettingsTableViewSectionReminders ) {
        BOOL tmpSwitchEnabled = (indexPath.row==1)?[FJTPunchManager lunchReminderEnabled]:[FJTPunchManager shiftReminderEnabled];
        [(UISwitch *)rtnCell.accessoryView setOn:tmpSwitchEnabled];
        rtnCell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    /*
    if ( indexPath.section == FJTSettingsTableViewSectionLocation ) {
        if ( indexPath.row == 0 ) {
            NSString *tmpDetailLabelText = @"Tap to set location...";
            CLPlacemark *tmpWorkLocationPlacemark = [FJTPunchManager workLocationPlacemark];
            if ( tmpWorkLocationPlacemark ) {
                // TOOD: format placemark into string
                tmpDetailLabelText = [NSString stringWithFormat:@"%@ %@", tmpWorkLocationPlacemark.subThoroughfare, tmpWorkLocationPlacemark.thoroughfare];
            }
            rtnCell.detailTextLabel.text = tmpDetailLabelText;
        } else {
            if ( [rtnCell.accessoryView respondsToSelector:@selector(setEnabled:)] ) {
                BOOL tmpLocationEnabled = NO;
                if ( [FJTPunchManager workLocationPlacemark] ) {
                    tmpLocationEnabled = YES;
                }
                BOOL tmpSwitchEnabled = (indexPath.row==1)?[FJTPunchManager punchInReminderEnabled]:[FJTPunchManager punchOutReminderEnabled];
                [(UISwitch *)rtnCell.accessoryView setEnabled:tmpLocationEnabled];
                [(UISwitch *)rtnCell.accessoryView setOn:tmpSwitchEnabled];
                rtnCell.textLabel.textColor = tmpLocationEnabled?[UIColor blackColor]:[UIColor lightGrayColor];
                rtnCell.detailTextLabel.textColor = [UIColor lightGrayColor];
            }
        }
    }
     */
    
    return rtnCell;
}

/*
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL rtnStatus = NO;
    
    if ( indexPath.section == 0 && indexPath.row == 0 ) {
        rtnStatus = YES;
    } else if ( indexPath.section == 2 ) {
        rtnStatus = YES;
    }
    
    return rtnStatus;
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return FJTSettingsTableViewSectionCount;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ( indexPath.section == FJTSettingsTableViewSectionClearButton ) {
        UIAlertController *tmpConfirmationSheet = [UIAlertController alertControllerWithTitle:@"Are you sure you want\nto remove all punches?" message:@"There is no going back." preferredStyle:UIAlertControllerStyleActionSheet];
        [tmpConfirmationSheet addAction:[UIAlertAction actionWithTitle:@"Delete All Punches" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            // do the needful
            NSArray *tmpPunches = [[FJTPunchManager punches] copy];
            for ( FJTPunch *tmpPunch in tmpPunches ) {
                [FJTPunchManager deletePunch:tmpPunch];
            }
        }]];
        [tmpConfirmationSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:tmpConfirmationSheet animated:YES completion:nil];
    }
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat rtnHeight = 0.0f;
    
    if ( section == 2 ) {
        rtnHeight = 180.0f;
    }
    
    return rtnHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *rtnView = nil;
    
    if ( section == 2 ) {
        rtnView = [UIView new];
        [rtnView setBackgroundColor:[UIColor clearColor]];
    }
    
    return rtnView;
}
*/

@end
