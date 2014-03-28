//
//  FJTFirstViewController.h
//  taco
//
//  Created by Ian Meyer on 3/27/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJTPunchViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *bigLabel;
@property (nonatomic, weak) IBOutlet UILabel *littleLabel;

@property (nonatomic, weak) IBOutlet UIButton *punchButton;

- (IBAction)punchButtonPressed:(id)sender;

@end
