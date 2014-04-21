//
//  FJTSecondViewController.m
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTHistoryViewController.h"

#define kFJTHistoryCellIdentifier @"FJTHistoryCellIdentifier"
#define kFJTEmptyCellIdentifier @"FJTEmptyCellIdentifier"


@interface FJTHistoryCell : UITableViewCell

@end

@implementation FJTHistoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ( self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier] ) {
        // customize?
        [self setBackgroundColor:[UIColor clearColor]];
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

@end

@implementation FJTHistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[FJTHistoryCell class] forCellReuseIdentifier:kFJTHistoryCellIdentifier];
    [self.tableView registerClass:[FJTEmptyCell class] forCellReuseIdentifier:kFJTEmptyCellIdentifier];
    
    [self.navigationItem setLeftBarButtonItem:self.editButtonItem];
    [self.editButtonItem setAction:@selector(editButtonPressed:)];
    
    // [self.navigationController.toolbar setBarStyle:UIBarStyleBlack];
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
        [self.navigationItem setPrompt:[NSString stringWithFormat:@"Select items to share, delete, or %@.",self.segmentedControl.selectedSegmentIndex==0?@"archive":@"unarchive"]];
    } else {
        [self.navigationItem setPrompt:nil];
    }
}

- (IBAction)deleteButtonPressed:(id)sender
{
    NSArray *tmpIndexPathsForSelectedRows = self.tableView.indexPathsForSelectedRows;
    
    NSMutableArray *tmpPunchesToDelete = [NSMutableArray array];
    for ( NSIndexPath *tmpSelectedIndexPath in tmpIndexPathsForSelectedRows ) {
       [tmpPunchesToDelete addObject:[self.recentPunches objectAtIndex:tmpSelectedIndexPath.row]];
    }

    NSMutableArray *tmpIndexPathsForDeletedRows = [NSMutableArray array];
    for ( FJTPunch *tmpPunch in tmpPunchesToDelete ) {
        if ( [FJTPunchManager deletePunch:tmpPunch] ) {
            [tmpIndexPathsForDeletedRows addObject:[tmpIndexPathsForSelectedRows objectAtIndex:[tmpPunchesToDelete indexOfObject:tmpPunch]]];
        }
    }
    
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
                [tmpPunchesToShare addObject:[[self currentPunches] objectAtIndex:tmpSelectedIndexPath.row]];
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
                                  [[FJTFormatter timeFormatter] stringFromDate:tmpPunch.punchDate],
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
            [tmpPunchesToArchive addObject:[[self currentPunches] objectAtIndex:tmpSelectedIndexPath.row]];
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
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
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

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationFade];
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

- (NSArray *)archivedPunches
{
    if ( !_archivedPunches ) {
        // load
        [self loadPunches];
    }
    
    return _archivedPunches;
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
    
    _recentPunches = [tmpPunches filteredArrayUsingPredicate:tmpRecentPunchesPredicate];
    _archivedPunches = [tmpPunches filteredArrayUsingPredicate:tmpArchivedPunchesPredicate];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self currentPunches].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *tmpCellIdentifier = nil;
    
    if ( [self currentPunches].count == 0 ) {
        tmpCellIdentifier = kFJTEmptyCellIdentifier;
    } else {
        tmpCellIdentifier = kFJTHistoryCellIdentifier;
    }
    
    UITableViewCell *rtnCell = [tableView dequeueReusableCellWithIdentifier:tmpCellIdentifier forIndexPath:indexPath];
    
    if ( self.recentPunches.count > 0 ) {
        // set up cell to display punch
        FJTPunch *tmpPunch = [[self currentPunches] objectAtIndex:indexPath.row];
        
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
        [rtnCell.detailTextLabel setText:[NSString stringWithFormat:@"%@ %@",
                                          [[FJTFormatter dateFormatter] stringFromDate:tmpPunch.punchDate],
                                          [[FJTFormatter timeFormatter] stringFromDate:tmpPunch.punchDate]]];
        
    } /* else {
        // empty cell
    } */
    
    return rtnCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( !self.tableView.isEditing ) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
        FJTPunch *tmpPunch = [[self currentPunches] objectAtIndex:indexPath.row];
        if ( [FJTPunchManager deletePunch:tmpPunch] ) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self updateStatus];
        }
    }
}

@end