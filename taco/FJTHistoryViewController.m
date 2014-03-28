//
//  FJTSecondViewController.m
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTHistoryViewController.h"

#define kFJTHistoryCellIdentifier @"FJTHistoryCellIdentifier"

@interface FJTHistoryCell : UITableViewCell

@end

@implementation FJTHistoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ( self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier] ) {
        // customize?
    }    
    return self;
}

@end

@interface FJTHistoryViewController ()

@property (nonatomic, strong) NSArray *history;

@end

@implementation FJTHistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[FJTHistoryCell class] forCellReuseIdentifier:kFJTHistoryCellIdentifier];

    [self.navigationItem setRightBarButtonItem:self.editButtonItem];
    // [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed)]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    _history = nil;
}

- (void)shareButtonPressed
{
    
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
    UITableViewCell *rtnCell = [tableView dequeueReusableCellWithIdentifier:kFJTHistoryCellIdentifier forIndexPath:indexPath];
    
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
    
    return rtnCell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
        FJTPunch *tmpPunch = [self.history objectAtIndex:indexPath.row];
        if ( [FJTPunchManager deletePunch:tmpPunch] ) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

@end
