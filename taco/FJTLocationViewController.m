//
//  FJTLocationViewController.m
//  taco
//
//  Created by Ian Meyer on 3/30/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTLocationViewController.h"

#import "FJTLocationManager.h"

#define kFJTLocationSearchResultCellIdentifier @"FJTLocationSearchResultCellIdentifier"

@interface FJTLocationViewController () <MKMapViewDelegate>

@property (nonatomic, strong) MKPointAnnotation *pinPointAnnotation;
@property (nonatomic, strong) MKPinAnnotationView *pinAnnotationView;
// @property (nonatomic, strong) MKPlacemark *placemark; // reverse geocoded address info

@property (nonatomic) BOOL shouldMoveToNextUserLocation;

@end

@implementation FJTLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self setTitle:@"Work Location"];
    
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    // [self.view setBackgroundColor:[UIColor orangeColor]];
    // [self.view.layer setBorderColor:[UIColor purpleColor].CGColor];
    // [self.view.layer setBorderWidth:2.0f];
    
    [self setHidesBottomBarWhenPushed:YES];
    
    [self setPlacemark:[FJTPunchManager workLocationPlacemark]];
    
    // [self.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    
    [self.searchContainer.layer setCornerRadius:5.0f];
    [self.searchContainer.layer setBorderWidth:1.0f];
    [self.searchContainer.layer setBorderColor:[UIColor colorWithRed:218/255.0f green:218/255.0f blue:222/255.0f alpha:1.0f].CGColor];

    [self.searchResults.layer setCornerRadius:5.0f];
    [self.searchResults.layer setBorderWidth:1.0f];
    [self.searchResults.layer setBorderColor:[UIColor colorWithRed:218/255.0f green:218/255.0f blue:222/255.0f alpha:1.0f].CGColor];

    [self.searchResults registerClass:[UITableViewCell class] forCellReuseIdentifier:kFJTLocationSearchResultCellIdentifier];
    
    [self.searchResults setContentInset:UIEdgeInsetsMake(20.0f, 0.f, 0.0f, 0.0f)];
    [self.searchResults setScrollIndicatorInsets:UIEdgeInsetsMake(18.0f, 0.f, 0.0f, 0.0f)];
    [self.searchResults.layer setCornerRadius:5.0f];

    UIView *tmpSearchIconPlaceholder = [[UIView alloc] initWithFrame:CGRectMake(5.0f, 0.0f, 28.0f, 30.0f)];
    [tmpSearchIconPlaceholder setBackgroundColor:[UIColor clearColor]];
    UIImageView *tmpIcon = [[UIImageView alloc] initWithFrame:CGRectMake(5.0f, 5.0f, 20.0f, 20.0f)];
    [tmpIcon setImage:[UIImage imageNamed:@"searchIconSmall.png"]];
    [tmpIcon setBackgroundColor:[UIColor clearColor]];
    [tmpIcon setContentMode:UIViewContentModeCenter];
    [tmpIcon setAlpha:0.5f];
    [tmpSearchIconPlaceholder addSubview:tmpIcon];
    [self.searchField setLeftView:tmpSearchIconPlaceholder];
    [self.searchField setLeftViewMode:UITextFieldViewModeAlways];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateStatusLabel];
    
    [self.navigationController setToolbarHidden:NO animated:YES];

    // drop pin if we have a placemark
    if ( self.placemark ) {
        MKMapCamera *tmpCamera = self.mapView.camera;
        [tmpCamera setCenterCoordinate:self.placemark.location.coordinate];
        [tmpCamera setAltitude:1000];
        [self.mapView setCamera:tmpCamera animated:YES];
        
        [self dropPinAtCoordinate:self.placemark.location.coordinate];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)updateStatusLabel
{
    NSString *tmpStatusLabelText = @"LOL WUT";
    
    if ( self.placemark ) {
        self.trashBarButtonItem.enabled = YES;
        if ( self.pinPointAnnotation && self.placemark ) {
            tmpStatusLabelText = [NSString stringWithFormat:@"%@ %@", self.placemark.subThoroughfare, self.placemark.thoroughfare]; // TODO: show address from placemark
        } else {
            tmpStatusLabelText = @"Loading...";
        }
    } else {
        self.trashBarButtonItem.enabled = NO;
        tmpStatusLabelText = @"No Location Set";
    }
    
    // [self.searchField setText:tmpStatusLabelText];
    [self.statusLabel setText:tmpStatusLabelText];
}

- (void)dropPinAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    MKPointAnnotation *tmpPinPointAnnotation = [[MKPointAnnotation alloc] init];
    [tmpPinPointAnnotation setCoordinate:coordinate];
    [self.mapView addAnnotation:tmpPinPointAnnotation];
    [self setPinPointAnnotation:tmpPinPointAnnotation];
    
    [self updatePinPlacemark];
    
    [self updateStatusLabel];
}

- (void)updatePinPlacemark
{
    if ( self.pinPointAnnotation ) {
        
        [self setPlacemark:nil];
        
        // self.statusBarButtonItem.title = @"Updating...";
        self.statusLabel.text = @"Updating...";
        
        CLGeocoder *tmpGeocoder = [[CLGeocoder alloc] init];
        [tmpGeocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:self.pinPointAnnotation.coordinate.latitude longitude:self.pinPointAnnotation.coordinate.longitude]
                          completionHandler:^(NSArray *placemarks, NSError *error) {
                              if ( error ) {
                                  // self.statusBarButtonItem.title = @"Error";
                                  self.statusLabel.text = @"Error";
                              } else {
                                  CLPlacemark *tmpPlacemark = placemarks.firstObject;
                                  // MKPlacemark.h: To create an MKPlacemark from a CLPlacemark, call [MKPlacemark initWithPlacemark:] passing the CLPlacemark instance that is returned by CLGeocoder.
                                  [self setPlacemark:[[MKPlacemark alloc] initWithPlacemark:tmpPlacemark]]; 
                                  [FJTPunchManager setWorkLocationPlacemark:tmpPlacemark];
                                  [self updateStatusLabel];
                              }
                          }];
        
    }
}

- (void)longPressGestureRecognizerFired:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if ( gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // remove existing pin
        if ( self.pinPointAnnotation ) {
            [self.mapView removeAnnotation:self.pinPointAnnotation];
        }
        // and drop a new one
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        [self dropPinAtCoordinate:touchMapCoordinate];
    }
    
    return;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    // NSLog(@"didAddAnnotationViews: %@", views);
    for ( MKAnnotationView *tmpAnnotationView in views ) {
        NSLog(@"annotation view: %@", tmpAnnotationView);
        if ( [tmpAnnotationView.annotation isKindOfClass:[MKUserLocation class]] ) {
            [tmpAnnotationView setEnabled:NO]; // prevents responding to touches (and fucking with the gesture recognizer that drops the pin)
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if ( newState == MKAnnotationViewDragStateEnding ) {
        [self updatePinPlacemark];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation
{
    MKPinAnnotationView *rtnAnnotation = nil;
    
    if ( [annotation isKindOfClass:[MKUserLocation class]] ) {
        // ???
    } else if ( [annotation isKindOfClass:[MKPointAnnotation class]] ) {
        rtnAnnotation = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"FJTLocationAnnotationView"];
        rtnAnnotation.pinColor = MKPinAnnotationColorRed;
        rtnAnnotation.animatesDrop = YES;
        rtnAnnotation.canShowCallout = NO;
        rtnAnnotation.draggable = YES;
        [self setPinAnnotationView:rtnAnnotation];
    }
    
    return rtnAnnotation;
}

- (void)trashButtonPressed:(id)sender
{
    if ( self.placemark ) {
        [self.mapView removeAnnotation:self.pinPointAnnotation];
        [self setPinPointAnnotation:nil];
        [self setPlacemark:nil];
        [FJTPunchManager setWorkLocationPlacemark:nil];
        [self updateStatusLabel];
    }
}

- (void)locationButtonPressed:(id)sender
{
    if ( !self.mapView.showsUserLocation ) {
        // going to enable location, maybe?
        if ( [FJTLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ) {
            [[FJTLocationManager defaultManager] requestAlwaysAuthorization];
        }
    }

    if ( [FJTLocationManager authorizationStatus] != kCLAuthorizationStatusDenied
        && [FJTLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted ) {
        [self.mapView setShowsUserLocation:!self.mapView.showsUserLocation];
    }

    [self.locationBarButtonItem setImage:self.mapView.showsUserLocation?[UIImage imageNamed:@"location-on"]:[UIImage imageNamed:@"location"]];
    
    if ( self.mapView.showsUserLocation ) {
        [self setShouldMoveToNextUserLocation:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if ( self.shouldMoveToNextUserLocation ) {
        MKMapCamera *tmpCamera = [mapView.camera copy];
        [tmpCamera setCenterCoordinate:userLocation.coordinate];
        [tmpCamera setAltitude:1000];
        [mapView setCamera:tmpCamera animated:YES];
        [self setShouldMoveToNextUserLocation:NO];
    }
}

#pragma mark - Search Field
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // ???
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // ???
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    // [self showSearchResults];
    [self showSpinner];
    
    return NO;
}

- (void)dismissSearchTapRecognizerFired:(id)sender
{
    [self.searchField resignFirstResponder];
}

- (void)showSpinner
{
    UIView *tmpSpinnerContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
    [tmpSpinnerContainer setBackgroundColor:[UIColor clearColor]];
    UIActivityIndicatorView *tmpSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [tmpSpinner setCenter:tmpSpinnerContainer.center];
    [tmpSpinnerContainer addSubview:tmpSpinner];
    [tmpSpinner startAnimating];
    [self.searchField setRightView:tmpSpinnerContainer];
    [self.searchField setRightViewMode:UITextFieldViewModeAlways];
}

- (void)showSearchResults
{
    [self.searchResults setAlpha:0.0f];
    [self.searchResults setHidden:NO];
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [self.searchResults setAlpha:1.0f];
                     }
                     completion:^(BOOL finished) {
                         if ( finished ) {
                             [self.dismissSearchTapRecognizer setEnabled:YES];
                         }
                     }];
}

- (void)hideSearchResults
{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [self.searchResults setAlpha:0.0f];
                     }
                     completion:^(BOOL finished) {
                         if ( finished ) {
                             [self.searchResults setHidden:YES];
                             [self.dismissSearchTapRecognizer setEnabled:NO];
                         }
                     }];
}

 #pragma mark - Table View (Search Results)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *rtnCell = [tableView dequeueReusableCellWithIdentifier:kFJTLocationSearchResultCellIdentifier forIndexPath:indexPath];
    
    [rtnCell.imageView setImage:[UIImage imageNamed:@"placeIcon"]];
    [rtnCell.textLabel setText:@[@"560 Broadway, New York, NY", @"560 Broadway, Brooklyn, NY", @"LOL WUT"][indexPath.row%3]];
    [rtnCell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f]];
    [rtnCell setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.7f]];
    
    [rtnCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return rtnCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.searchField resignFirstResponder];
    [self hideSearchResults];
}

@end
