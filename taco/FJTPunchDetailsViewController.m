//
//  FJTPunchDetailsViewController.m
//  taco
//
//  Created by Ian Meyer on 5/2/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTPunchDetailsViewController.h"

@interface FJTPunchDetailsViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIView *inputAccessoryView;
@property (nonatomic, strong) UIBarButtonItem *previousButton;
@property (nonatomic, strong) UIBarButtonItem *nextButton;
@property (nonatomic, strong) UIDatePicker *datePicker;

@end

@implementation FJTPunchDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIDatePicker *tmpDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    [tmpDatePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [tmpDatePicker addTarget:self action:@selector(datePickerDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.punchDateTextField setInputView:tmpDatePicker];
    [self setDatePicker:tmpDatePicker];
    
    [self.punchDateTextField setInputAccessoryView:[self inputAccessoryView]];
    [self.punchNotesTextView setInputAccessoryView:[self inputAccessoryView]];
    
    [self.punchNotesTextView setShowsHorizontalScrollIndicator:NO];
    
    [self.punchDateTextField.layer setCornerRadius:5.0f];
    [self.punchDateTextField.layer setBorderWidth:1.0f];
    [self.punchDateTextField.layer setBorderColor:[UIColor colorWithRed:218/255.0f green:218/255.0f blue:222/255.0f alpha:1.0f].CGColor];

    [self.punchNotesTextView.layer setCornerRadius:5.0f];
    [self.punchNotesTextView.layer setBorderWidth:1.0f];
    [self.punchNotesTextView.layer setBorderColor:[UIColor colorWithRed:218/255.0f green:218/255.0f blue:222/255.0f alpha:1.0f].CGColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ( self.punch ) {
        
        if ( self.punch.punchNotes && self.punch.punchNotes.length > 0 ) {
            [self.punchNotesTextView setText:self.punch.punchNotes];
            [self.punchNotesTextView setTextColor:[UIColor blackColor]];
        } else {
            [self.punchNotesTextView setText:@"Tap to add notes..."];
            [self.punchNotesTextView setTextColor:[UIColor darkGrayColor]];
        }
        
        NSInteger tmpSelectedIndex = UISegmentedControlNoSegment;
        if ( self.punch.punchType == FJTPunchTypePunchIn ) {
            tmpSelectedIndex = 0;
        } else if ( self.punch.punchType == FJTPunchTypePunchOut ) {
            tmpSelectedIndex = 1;
        }
        [self.punchTypeSegmentedControl setSelectedSegmentIndex:tmpSelectedIndex];
        
        NSString *tmpPunchDateString = [NSString stringWithFormat:@"%@ %@",
                                        [[FJTFormatter dateFormatter] stringFromDate:self.punch.punchDate],
                                        [[FJTFormatter longTimeFormatter] stringFromDate:self.punch.punchDate]];
        [self.punchDateTextField setText:tmpPunchDateString];
        
        // get rid of seconds for the date picker date
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *tmpComponents = [calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit ) fromDate:self.punch.punchDate];
        [self.datePicker setDate:[calendar dateFromComponents:tmpComponents]];
    }
}

- (void)datePickerDidChange:(UIDatePicker *)datePicker
{
    NSString *tmpPunchDateString = [NSString stringWithFormat:@"%@ %@",
                                    [[FJTFormatter dateFormatter] stringFromDate:datePicker.date],
                                    [[FJTFormatter shortTimeFormatter] stringFromDate:datePicker.date]];
    [self.punchDateTextField setText:tmpPunchDateString];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ( [textView.text isEqualToString:@"Tap to add notes..."] ) {
        [textView setText:nil];
        [textView setTextColor:[UIColor blackColor]];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.previousButton setEnabled:NO];
    [self.nextButton setEnabled:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.previousButton setEnabled:YES];
    [self.nextButton setEnabled:NO];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    // if we have some notes...
    if ( textView.text && textView.text.length > 0 ) {
        // update the punch
        [self.punch setPunchNotes:textView.text];
    } else {
        // or clear the notes
        [self.punch setPunchNotes:nil];
    }

    // and save the change
    [FJTPunchManager saveData];

    // finally, if we don't have anything, restore the placeholder
    if ( !textView.text || [textView.text isEqualToString:@""] ) {
        [textView setText:@"Tap to add notes..."];
        [textView setTextColor:[UIColor darkGrayColor]];
    }
}

- (UIView *)inputAccessoryView
{
    if ( !_inputAccessoryView ) {
        
        UIToolbar *tmpToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 44.0f)];
        
        UIBarButtonItem *tmpPreviousButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"iconprev"] style:UIBarButtonItemStylePlain target:self action:@selector(previousButtonPressed)];
        UIBarButtonItem *tmpNextButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"iconnext"] style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed)];
        UIBarButtonItem *tmpFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *tmpDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
        
        [tmpToolbar setItems:@[tmpPreviousButton, tmpNextButton, tmpFlexibleSpace, tmpDoneButton]];
        
        [self setPreviousButton:tmpPreviousButton];
        [self setNextButton:tmpNextButton];
        
        [tmpToolbar setBarStyle:UIBarStyleBlack];
        [tmpToolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        
        UIInputView *tmpInputView = [[UIInputView alloc] initWithFrame:tmpToolbar.bounds inputViewStyle:UIInputViewStyleDefault];
        [tmpInputView addSubview:tmpToolbar];
        
        _inputAccessoryView = tmpInputView;
    }
    
    return _inputAccessoryView;
}

- (void)previousButtonPressed
{
    if ( [self.punchNotesTextView isFirstResponder] ) {
        [self.punchDateTextField becomeFirstResponder];
    }
}

- (void)nextButtonPressed
{
    if ( [self.punchDateTextField isFirstResponder] ) {
        [self.punchNotesTextView becomeFirstResponder];
    }
}

- (void)doneButtonPressed
{
    [self.punchDateTextField resignFirstResponder];
    [self.punchNotesTextView resignFirstResponder];
}

@end
