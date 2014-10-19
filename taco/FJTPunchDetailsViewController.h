//
//  FJTPunchDetailsViewController.h
//  taco
//
//  Created by Ian Meyer on 5/2/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJTPunchDetailsViewController : UIViewController

@property (nonatomic, strong) FJTPunch *punch;

@property (nonatomic, weak) IBOutlet UISegmentedControl *punchTypeSegmentedControl;
@property (nonatomic, weak) IBOutlet UITextField *punchDateTextField;
@property (nonatomic, weak) IBOutlet UITextView *punchNotesTextView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textFieldBottomSpaceConstraint;

@end
