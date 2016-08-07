//
//  FJTLocationViewController.h
//  taco
//
//  Created by Ian Meyer on 3/30/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MapKit/MapKit.h>

@class FJTLocationViewController;

@protocol FJTLocationViewControllerDelegate <NSObject>

- (void)locationViewController:(FJTLocationViewController *)viewController didSetPlacemark:(CLPlacemark *)placemark;

@end

@interface FJTLocationViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UILongPressGestureRecognizer *dropPinRecognizer;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *statusBarButtonItem;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *trashBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *locationBarButtonItem;

@property (nonatomic, weak) IBOutlet UIView *searchContainer;
@property (nonatomic, weak) IBOutlet UITextField *searchField;
@property (nonatomic, weak) IBOutlet UITableView *searchResults;
@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *dismissSearchTapRecognizer;
- (IBAction)dismissSearchTapRecognizerFired:(id)sender;

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) CLPlacemark *placemark;
@property (nonatomic, weak) NSObject <FJTLocationViewControllerDelegate> *delegate;

- (IBAction)trashButtonPressed:(id)sender;
- (IBAction)locationButtonPressed:(id)sender;
- (IBAction)longPressGestureRecognizerFired:(UILongPressGestureRecognizer *)gestureRecognizer;

@end