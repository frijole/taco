//
//  FJTSecondViewController.m
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTHistoryViewController.h"

#import "FJTPunchDetailsViewController.h"

#define kFJTHistoryCellIdentifier @"FJTHistoryCellIdentifier"

@interface FJTHistoryCell : UITableViewCell

@end

@implementation FJTHistoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ( self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier] ) {
        // customize?
        /*
        [self setBackgroundColor:[UIColor blackColor]];
        [self.textLabel setTextColor:[UIColor whiteColor]];
        [self.detailTextLabel setTextColor:[UIColor lightGrayColor]];
         */
    }
    return self;
}

@end


@interface FJTEmptyCell : UITableViewCell

@end

@implementation FJTEmptyCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ( self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier] ) {
        // customize?
        [self setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        
        UILabel *tmpCustomLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        [tmpCustomLabel setAutoresizingMask:(UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth)];
        [tmpCustomLabel setBackgroundColor:[UIColor clearColor]];
        [tmpCustomLabel setTextAlignment:NSTextAlignmentCenter];
        [tmpCustomLabel setText:@"No Punches Yet"];
        [self.contentView addSubview:tmpCustomLabel];
        
    }
    return self;
}

@end


@interface FJTHistoryViewController ()

@property (nonatomic, strong) UILabel *curtainView;

@property (nonatomic, strong) NSArray *recentPunches;
@property (nonatomic, strong) NSArray *archivedPunches;

@property (nonatomic, strong) NSArray               *recentPunchSectionKeys; // keys in sorted order for display
@property (nonatomic, strong) NSMutableDictionary   *recentPunchSectionData; // arrays of punches keyed by NSDates
@property (nonatomic, strong) NSArray               *archivedPunchSectionKeys; // keys in sorted order for display
@property (nonatomic, strong) NSMutableDictionary   *archivedPunchSectionData; // arrays of punches keyed by NSDates

@end

@implementation FJTHistoryViewController

@synthesize recentPunches = _recentPunches;
@synthesize archivedPunches = _archivedPunches;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[FJTHistoryCell class]    forCellReuseIdentifier:kFJTHistoryCellIdentifier];
    
    [self.navigationItem setLeftBarButtonItem:self.editButtonItem];
    [self.editButtonItem setAction:@selector(editButtonPressed:)];
    
    // [self.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    
    [self setTitle:@"History"];
    
    [self.navigationController.tabBarItem setImage:[UIImage imageNamed:@"iconHistory"]];
    [self.navigationController.tabBarItem setSelectedImage:[UIImage imageNamed:@"iconHistoryOn"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadPunches];
    [self.tableView reloadData];
    [self updateStatus];
}

- (void)didReceiveMemoryWarning
{
    _recentPunches = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    if ( self.tableView.indexPathsForSelectedRows.count > 0 ) {
        NSIndexPath *tmpFirstSelectedIndexPath = [[self.tableView indexPathsForSelectedRows] firstObject];
        FJTPunch *tmpPunch = [self punchForIndexPath:tmpFirstSelectedIndexPath];
        if ( [segue.destinationViewController respondsToSelector:@selector(setPunch:)] ) {
            [(FJTPunchDetailsViewController *)segue.destinationViewController setPunch:tmpPunch];
        }
    } else {
        NSLog(@"preparing for segue but no selection. wat?!");
    }
}

- (void)editButtonPressed:(id)sender
{
    [self.tableView setAllowsMultipleSelectionDuringEditing:!self.editing];
    [self updateStatus];
    
    [self setEditing:!self.editing animated:YES];
    
    [self.navigationController setToolbarHidden:!self.editing animated:YES];
    
    [self refreshPrompt];
}

- (void)refreshPrompt
{
    if ( self.isEditing ) {
        [self.navigationItem setPrompt:[NSString stringWithFormat:@"Select items to share, delete, or %@.",
                                        self.segmentedControl.selectedSegmentIndex==0?@"archive":@"unarchive"]];
    } else {
        [self.navigationItem setPrompt:nil];
    }
}

- (IBAction)deleteButtonPressed:(id)sender
{
    NSArray *tmpIndexPathsForSelectedRows = self.tableView.indexPathsForSelectedRows;
    
    NSMutableArray *tmpPunchesToDelete = [NSMutableArray array];
    for ( NSIndexPath *tmpSelectedIndexPath in tmpIndexPathsForSelectedRows ) {
       [tmpPunchesToDelete addObject:[self punchForIndexPath:tmpSelectedIndexPath]];
    }

    NSMutableArray *tmpIndexPathsForDeletedRows = [NSMutableArray array];
    for ( FJTPunch *tmpPunch in tmpPunchesToDelete ) {
        if ( [FJTPunchManager deletePunch:tmpPunch] ) {
            [tmpIndexPathsForDeletedRows addObject:[tmpIndexPathsForSelectedRows objectAtIndex:[tmpPunchesToDelete indexOfObject:tmpPunch]]];
        }
    }
    
    [self loadPunches];
    
    [self.tableView deleteRowsAtIndexPaths:tmpIndexPathsForDeletedRows withRowAnimation:UITableViewRowAnimationLeft];

    // if there aren't any punches left, use the edit button to end editing
    if ( self.recentPunches.count == 0 ) {
        [self editButtonPressed:nil];
    }
    
    [self updateStatus];
}

- (IBAction)shareButtonPressed:(id)sender
{
    if ( !self.isEditing ) {
        // not editing
        [self editButtonPressed:nil]; // activate via button action to present toolbar
    } else {
        // editing
        
        if ( self.tableView.indexPathsForSelectedRows.count > 0 ) {
            // we have some things to (un)archive
            NSMutableArray *tmpPunchesToShare = [NSMutableArray array];
            for ( NSIndexPath *tmpSelectedIndexPath in self.tableView.indexPathsForSelectedRows ) {
                [tmpPunchesToShare addObject:[self punchForIndexPath:tmpSelectedIndexPath]];
            }
            NSString *tmpShareString = @"Exported Punches:\n";
            for ( FJTPunch *tmpPunch in tmpPunchesToShare ) {
                NSString *tmpPunchTypeString = @"Unknown";
                if ( tmpPunch.punchType == FJTPunchTypePunchIn ) {
                    tmpPunchTypeString = @"In";
                } else if ( tmpPunch.punchType == FJTPunchTypePunchOut ) {
                    tmpPunchTypeString = @"Out";
                }
                tmpShareString = [tmpShareString stringByAppendingFormat:@"%@ at %@ on %@\n",
                                  tmpPunchTypeString,
                                  [[FJTFormatter longTimeFormatter] stringFromDate:tmpPunch.punchDate],
                                  [[FJTFormatter dateFormatter] stringFromDate:tmpPunch.punchDate]
                                  ];
            }
            UIActivityViewController *tmpActivityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[tmpShareString] applicationActivities:nil];
            [self presentViewController:tmpActivityViewController animated:YES completion:nil];

        } else {
            [MMAlertView showAlertViewWithTitle:@"No Selection"
                                        message:@"You haven't selected\nanything to share"];
        }
    }
}

- (IBAction)archiveButtonPressed:(id)sender
{
    if ( self.tableView.indexPathsForSelectedRows.count > 0 ) {
        // we have some things to (un)archive
        NSMutableArray *tmpPunchesToArchive = [NSMutableArray array];
        for ( NSIndexPath *tmpSelectedIndexPath in self.tableView.indexPathsForSelectedRows ) {
            [tmpPunchesToArchive addObject:[self punchForIndexPath:tmpSelectedIndexPath]];
        }
        BOOL tmpShouldArchive = YES;
        if ( self.segmentedControl.selectedSegmentIndex == 1 ) {
            tmpShouldArchive = NO;
        }
        for ( FJTPunch *tmpPunch in tmpPunchesToArchive ) {
            [tmpPunch setArchived:tmpShouldArchive];
        }
        [FJTPunchManager saveData];
        
        [self loadPunches];
        
        [self.tableView reloadData];
    } else {
        NSString *tmpArchiveString = self.segmentedControl.selectedSegmentIndex==0?@"archive":@"unarchive";
        NSString *tmpArchiveMessage = [NSString stringWithFormat:@"You haven't selected\nanything to %@", tmpArchiveString];
        [MMAlertView showAlertViewWithTitle:@"No Selection"
                                    message:tmpArchiveMessage];
    }
}

- (IBAction)segmentedControlChanged:(id)sender
{
    [self refreshPrompt];
    [self updateStatus];

    [self.tableView reloadData];
}

- (void)updateStatus
{
    NSString *tmpString = @"LOL WUT";
    
    if ( self.tableView.indexPathsForSelectedRows.count > 0 ) {
        tmpString = [NSString stringWithFormat:@"%@ selected", @(self.tableView.indexPathsForSelectedRows.count)];
    } else {
        tmpString = [NSString stringWithFormat:@"%@ punches", @([self currentPunches].count)];
    }
    
    [self.statusBarButtonItem setTitle:tmpString];
    
//    BOOL tmpEnableButtons = [self currentPunches].count>0;
//    [self.shareBarButtonItem setEnabled:tmpEnableButtons];
//    [self.deleteBarButtonItem setEnabled:tmpEnableButtons];
//    [self.archiveBarButtonItem setEnabled:tmpEnableButtons];
}

- (NSArray *)recentPunches
{
    if ( !_recentPunches ) {
        // load
        [self loadPunches];
    }
    
    return _recentPunches;
}

- (NSArray *)recentPunchSectionKeys
{
    if ( !_recentPunchSectionKeys ) {
        _recentPunchSectionKeys = [NSArray array];
    }
    
    return _recentPunchSectionKeys;
}

- (NSMutableDictionary *)recentPunchSectionData
{
    if ( !_recentPunchSectionData ) {
        _recentPunchSectionData = [NSMutableDictionary dictionary];
    }
    
    return _recentPunchSectionData;
}

- (void)setRecentPunches:(NSArray *)recentPunches
{
    _recentPunches = recentPunches;
    
    // clear the section stuff, will be regenerated
    _recentPunchSectionData = nil;
    _recentPunchSectionKeys = nil;

    for ( FJTPunch *tmpPunch in _recentPunches ) {
        
        NSDate *tmpPunchDay = [tmpPunch.punchDate dateAtBeginningOfDay];
        
        NSMutableArray *tmpPunchesOnThisDay = [self.recentPunchSectionData objectForKey:tmpPunchDay];
        if ( !tmpPunchesOnThisDay ) {
            tmpPunchesOnThisDay = [NSMutableArray array];
            [self.recentPunchSectionData setObject:tmpPunchesOnThisDay forKey:tmpPunchDay];
        }
        [tmpPunchesOnThisDay addObject:tmpPunch];
    }
    
    NSArray *tmpUnsortedDays = [self.recentPunchSectionData allKeys];
    [self setRecentPunchSectionKeys:[[[tmpUnsortedDays sortedArrayUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects]];
}

- (NSArray *)archivedPunchSectionKeys
{
    if ( !_archivedPunchSectionKeys ) {
        _archivedPunchSectionKeys = [NSArray array];
    }
    
    return _archivedPunchSectionKeys;
}

- (NSMutableDictionary *)archivedPunchSectionData
{
    if ( !_archivedPunchSectionData ) {
        _archivedPunchSectionData = [NSMutableDictionary dictionary];
    }
    
    return _archivedPunchSectionData;
}

- (NSArray *)archivedPunches
{
    if ( !_archivedPunches ) {
        // load
        [self loadPunches];
    }
    
    return _archivedPunches;
}

- (void)setArchivedPunches:(NSArray *)archivedPunches
{
    _archivedPunches = archivedPunches;
    
    // clear the section stuff, will be regenerated
    _archivedPunchSectionData = nil;
    _archivedPunchSectionKeys = nil;
    
    for ( FJTPunch *tmpPunch in _archivedPunches ) {
        
        NSDate *tmpPunchDay = [tmpPunch.punchDate dateAtBeginningOfDay];
        
        NSMutableArray *tmpPunchesOnThisDay = [self.archivedPunchSectionData objectForKey:tmpPunchDay];
        if ( !tmpPunchesOnThisDay ) {
            tmpPunchesOnThisDay = [NSMutableArray array];
            [self.archivedPunchSectionData setObject:tmpPunchesOnThisDay forKey:tmpPunchDay];
        }
        [tmpPunchesOnThisDay addObject:tmpPunch];
    }
    
    NSArray *tmpUnsortedDays = [self.archivedPunchSectionData allKeys];
    [self setArchivedPunchSectionKeys:[[[tmpUnsortedDays sortedArrayUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects]];
}

- (NSArray *)currentPunches
{
    NSArray *rtnArray = nil;
    
    if ( self.segmentedControl.selectedSegmentIndex == 0 ) {
        rtnArray = [self recentPunches];
    } else {
        rtnArray = [self archivedPunches];
    }
    
    return rtnArray;
}

- (void)loadPunches
{
    NSArray *tmpPunches = [FJTPunchManager punches];;
    
    NSPredicate *tmpRecentPunchesPredicate = [NSPredicate predicateWithFormat:@"archived == NO"];
    NSPredicate *tmpArchivedPunchesPredicate = [NSPredicate predicateWithFormat:@"archived == YES"];
    
    [self setRecentPunches:[tmpPunches filteredArrayUsingPredicate:tmpRecentPunchesPredicate]];
    [self setArchivedPunches:[tmpPunches filteredArrayUsingPredicate:tmpArchivedPunchesPredicate]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger rtnCount = 0;
    
    if ( self.segmentedControl.selectedSegmentIndex == 0 ) {
        rtnCount = self.recentPunchSectionKeys.count;
    } else {
        rtnCount = self.archivedPunchSectionKeys.count;
    }
    
    return rtnCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rtnCount = 0;
    
    if ( self.segmentedControl.selectedSegmentIndex == 0 ) {
        rtnCount = [[self.recentPunchSectionData objectForKey:self.recentPunchSectionKeys[section]] count];
    } else {
        rtnCount = [[self.archivedPunchSectionData objectForKey:self.archivedPunchSectionKeys[section]] count];
    }
    
    return rtnCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *rtnString = nil;
    
    NSArray *tmpSectionsKeys = (self.segmentedControl.selectedSegmentIndex==0?[self recentPunchSectionKeys]:[self archivedPunchSectionKeys]);
    NSDate *tmpSectionDate = [tmpSectionsKeys objectAtIndex:section];
    rtnString = [[FJTFormatter dateFormatter] stringFromDate:tmpSectionDate];
    
    return rtnString;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *rtnCell = [tableView dequeueReusableCellWithIdentifier:kFJTHistoryCellIdentifier forIndexPath:indexPath];
    
    // set up cell to display punch
    FJTPunch *tmpPunch = [self punchForIndexPath:indexPath];
    
    NSString *tmpPunchTypeString = nil;
    switch ( tmpPunch.punchType ) {
        case FJTPunchTypePunchIn:
            tmpPunchTypeString = @"In";
            break;
        case FJTPunchTypePunchOut:
            tmpPunchTypeString = @"Out";
            break;
        case FJTPunchTypeUnset:
            tmpPunchTypeString = @"???";
            break;
    }

    [rtnCell.textLabel setText:tmpPunchTypeString];
    [rtnCell.detailTextLabel setText:[[FJTFormatter longTimeFormatter] stringFromDate:tmpPunch.punchDate]];

    return rtnCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( !self.tableView.isEditing ) {
        [self performSegueWithIdentifier:@"punchDetails" sender:nil];
    } else {
        [self updateStatus];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateStatus];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
        FJTPunch *tmpPunch = [self punchForIndexPath:indexPath];
        // if there is more than one punch in the section we are deleting from, we're just going to remove the row
        BOOL tmpShouldKeepSection = [self tableView:nil numberOfRowsInSection:indexPath.section] > 1;
        if ( [FJTPunchManager deletePunch:tmpPunch] ) {
            [self loadPunches];
            if ( tmpShouldKeepSection ) {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            } else {
                [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
            }
            
            [self updateStatus];
        }
    }
}

- (FJTPunch *)punchForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *tmpSectionsKeys = (self.segmentedControl.selectedSegmentIndex==0?[self recentPunchSectionKeys]:[self archivedPunchSectionKeys]);
    NSDictionary *tmpSectionData = (self.segmentedControl.selectedSegmentIndex==0?[self recentPunchSectionData]:[self archivedPunchSectionData]);
    NSArray *tmpSectionPunches = [tmpSectionData objectForKey:[tmpSectionsKeys objectAtIndex:indexPath.section]];
    FJTPunch *tmpPunch = [tmpSectionPunches objectAtIndex:indexPath.row];

    return tmpPunch;
}

@end