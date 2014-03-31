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
    NSString *tmpLastPunchText = @"Last Punch:\nNo punches yet.";
    NSString *tmpButtonTitle = @"Punch In";
    
    FJTPunch *tmpPunch = [FJTPunchManager punches].lastObject;
    if ( tmpPunch ) {
        tmpLastPunchText = [NSString stringWithFormat:@"Last Punch: %@\n%@ on %@",
                            tmpPunch.punchType==FJTPunchTypePunchOut?@"Out":@"In",
                            [[FJTFormatter timeFormatter] stringFromDate:tmpPunch.punchDate],
                            [[FJTFormatter dateFormatter] stringFromDate:tmpPunch.punchDate]];
    
        if ( tmpPunch.punchType == FJTPunchTypePunchIn ) {
            tmpButtonTitle = @"Punch Out";
        }
    }
    
    [self.littleLabel setText:tmpLastPunchText];
    [self.punchButton setTitle:tmpButtonTitle forState:UIControlStateNormal];
}

- (void)updateTimeLabel
{
    [self.bigLabel setText:[[FJTFormatter timeFormatter] stringFromDate:[NSDate date]]];
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
    }
    
    [self updatePunchLabel];
}

@end


@implementation FJTPunchRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tabBarItem setImage:[UIImage imageNamed:@"switch"]];
    [self.tabBarItem setSelectedImage:[UIImage imageNamed:@"switch-on"]];
}

@end
