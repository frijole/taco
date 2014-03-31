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
@property (nonatomic, strong) NSArray *history;

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
    
    [self.tableView reloadData];
    [self updateStatus];
}

- (void)didReceiveMemoryWarning
{
    _history = nil;
}

- (void)editButtonPressed:(id)sender
{
    [self.tableView setAllowsMultipleSelectionDuringEditing:!self.editing];
    [self updateStatus];
    
    [self setEditing:!self.editing animated:YES];
    
    [self.navigationController setToolbarHidden:!self.editing animated:YES];
    
    if ( self.isEditing ) {
        [self.navigationItem setPrompt:@"Select items to share, delete, or archive."];
    } else {
        [self.navigationItem setPrompt:nil];
    }
}

- (IBAction)deleteButtonPressed:(id)sender
{
    NSArray *tmpIndexPathsForSelectedRows = self.tableView.indexPathsForSelectedRows;
    
    NSMutableArray *tmpPunchesToDelete = [NSMutableArray array];
    for ( NSIndexPath *tmpSelectedIndexPath in tmpIndexPathsForSelectedRows ) {
       [tmpPunchesToDelete addObject:[self.history objectAtIndex:tmpSelectedIndexPath.row]];
    }

    NSMutableArray *tmpIndexPathsForDeletedRows = [NSMutableArray array];
    for ( FJTPunch *tmpPunch in tmpPunchesToDelete ) {
        if ( [FJTPunchManager deletePunch:tmpPunch] ) {
            [tmpIndexPathsForDeletedRows addObject:[tmpIndexPathsForSelectedRows objectAtIndex:[tmpPunchesToDelete indexOfObject:tmpPunch]]];
        }
    }
    
    [self.tableView deleteRowsAtIndexPaths:tmpIndexPathsForDeletedRows withRowAnimation:UITableViewRowAnimationLeft];

    // if there aren't any punches left, use the edit button to end editing
    if ( self.history.count == 0 ) {
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
        // TODO: export selection
        [self editButtonPressed:nil]; // deactivate via button action to clean up toolbar
    }
}

- (IBAction)archiveButtonPressed:(id)sender
{
    
}

- (void)updateStatus
{
    NSString *tmpString = @"LOL WUT";
    
    if ( self.tableView.indexPathsForSelectedRows.count > 0 ) {
        tmpString = [NSString stringWithFormat:@"%@ selected", @(self.tableView.indexPathsForSelectedRows.count)];
    } else {
        tmpString = [NSString stringWithFormat:@"%@ punches", @([self history].count)];
    }
    
    [self.statusBarButtonItem setTitle:tmpString];
    
    [self.navigationItem.leftBarButtonItem setEnabled:(self.history.count>0)];
    [self.navigationItem.rightBarButtonItem setEnabled:(self.history.count>0)];
}

- (NSArray *)history
{
    if ( !_history ) {
        // load
        _history = [FJTPunchManager punches];
    }
    
    return _history;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.history.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *tmpCellIdentifier = nil;
    
    if ( self.history.count == 0 ) {
        tmpCellIdentifier = kFJTEmptyCellIdentifier;
    } else {
        tmpCellIdentifier = kFJTHistoryCellIdentifier;
    }
    
    UITableViewCell *rtnCell = [tableView dequeueReusableCellWithIdentifier:tmpCellIdentifier forIndexPath:indexPath];
    
    if ( self.history.count > 0 ) {
        // set up cell to display punch
        FJTPunch *tmpPunch = [self.history objectAtIndex:indexPath.row];
        
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
        FJTPunch *tmpPunch = [self.history objectAtIndex:indexPath.row];
        if ( [FJTPunchManager deletePunch:tmpPunch] ) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self updateStatus];
        }
    }
}

@end