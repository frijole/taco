//
//  MMAlertView.m
//  magicmap3
//
//  Created by Ian Meyer on 2/10/12.
//  Copyright (c) 2012 Adelie Software. All rights reserved.
//

#import "MMAlertView.h"

@interface MMAlertView () <UITextFieldDelegate>

@end

@implementation MMAlertView

@synthesize cancelBlock = _cancelBlock;
@synthesize acceptBlock = _acceptBlock;

#pragma mark - 
#pragma mark UIAlertView Overrides and Extensions
- (void)show
{
    if ( self.maxInputLength ) {
        
        if ( self.alertViewStyle != UIAlertViewStyleDefault ) {

            if ( [self textFieldAtIndex:0].delegate )
                NSLog(@"textFieldAtIndex:0 has a delegate already. replacing to handle maxInputLength");
            
            [[self textFieldAtIndex:0] setDelegate:self];
            
            if ( self.alertViewStyle == UIAlertViewStyleLoginAndPasswordInput ) {
                
                if ( [self textFieldAtIndex:1].delegate )
                    NSLog(@"textFieldAtIndex:1 has a delegate already. replacing to handle maxInputLength");

                [[self textFieldAtIndex:1] setDelegate:self];
            }
        }
    }
    
    [super show];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL rtnStatus = YES;
    
    NSString *tmpChangedString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ( tmpChangedString.length > self.maxInputLength )
        rtnStatus = NO;
    
    return rtnStatus;
}


#pragma mark -
#pragma mark MMAlertView class methods
+ (void)showAlertViewWithTitle:(NSString *)inTitle message:(NSString *)inMessage
{
	[self showAlertViewWithTitle:inTitle message:inMessage closeButtonTitle:@"Close"];
}

+ (void)showAlertViewWithTitle:(NSString *)inTitle message:(NSString *)inMessage closeButtonTitle:(NSString *)inCloseButtonTitle
{
	[self showAlertViewWithTitle:inTitle message:inMessage closeButtonTitle:inCloseButtonTitle closeBlock:nil];
}

+ (void)showAlertViewWithTitle:(NSString *)inTitle message:(NSString *)inMessage closeButtonTitle:(NSString *)inCloseButtonTitle closeBlock:(MMAlertViewButtonPressedBlockType)inCloseBlock
{
	[self showAlertViewWithTitle:inTitle message:inMessage cancelButtonTitle:inCloseButtonTitle acceptButtonTitle:nil cancelBlock:inCloseBlock acceptBlock:nil];
}

+ (MMAlertView *)alertViewWithTitle:(NSString *)inTitle message:(NSString *)inMessage closeButtonTitle:(NSString *)inCloseButtonTitle closeBlock:(MMAlertViewButtonPressedBlockType)inCloseBlock
{
	return [self alertViewWithTitle:inTitle message:inMessage cancelButtonTitle:inCloseButtonTitle acceptButtonTitle:nil cancelBlock:inCloseBlock acceptBlock:nil];
}

+ (void)showAlertViewWithTitle:(NSString *)inTitle message:(NSString *)inMessage cancelButtonTitle:(NSString *)inCancelButtonTitle acceptButtonTitle:(NSString *)inAcceptButtonTitle cancelBlock:(MMAlertViewButtonPressedBlockType)inCancelBlock acceptBlock:(MMAlertViewButtonPressedBlockType)inAcceptBlock
{
	[[[self class] alertViewWithTitle:inTitle message:inMessage cancelButtonTitle:inCancelButtonTitle acceptButtonTitle:inAcceptButtonTitle cancelBlock:inCancelBlock acceptBlock:inAcceptBlock] show];
}

+ (MMAlertView *)alertViewWithTitle:(NSString *)inTitle message:(NSString *)inMessage cancelButtonTitle:(NSString *)inCancelButtonTitle acceptButtonTitle:(NSString *)inAcceptButtonTitle cancelBlock:(MMAlertViewButtonPressedBlockType)inCancelBlock acceptBlock:(MMAlertViewButtonPressedBlockType)inAcceptBlock
{
	MMAlertView *tmpAlertView = [[MMAlertView alloc] initWithTitle:inTitle message:inMessage delegate:nil cancelButtonTitle:inCancelButtonTitle otherButtonTitles:inAcceptButtonTitle, nil];
	[tmpAlertView setDelegate:tmpAlertView];
	[tmpAlertView setCancelBlock:inCancelBlock];
	[tmpAlertView setAcceptBlock:inAcceptBlock];
    return tmpAlertView;
}

#pragma mark -
#pragma mark UIAlertView property functions
- (void)setDelegate:(id)delegate
{
	NSAssert(delegate == self || delegate == nil, @"The delegate must not be overwritten.");
	[super setDelegate:delegate];
}

#pragma mark -
#pragma mark UIAlertView delegate functions
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [alertView cancelButtonIndex])
	{
		if (_cancelBlock)
			_cancelBlock();
	}
	else
	{
		if (_acceptBlock)
			_acceptBlock();
	}
}

@end
