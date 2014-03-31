//
//  FJTSecondViewController.h
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJTHistoryViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *statusBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *shareBarButtonItem;

- (IBAction)deleteButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;

@end