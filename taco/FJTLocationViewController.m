//
//  FJTLocationViewController.m
//  taco
//
//  Created by Ian Meyer on 3/30/14.
//  Copyright (c) 2014 Ian Meyer. All rights reserved.
//

#import "FJTLocationViewController.h"

#import <MapKit/MapKit.h>

@interface FJTLocationViewController () <MKMapViewDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UILongPressGestureRecognizer *dropPinRecognizer;
@property (nonatomic, strong) MKPointAnnotation *pinPointAnnotation;
@property (nonatomic, strong) MKPinAnnotationView *pinAnnotationView;
@property (nonatomic, strong) MKPlacemark *pinPlacemark; // reverse geocoded address info

@property (nonatomic, weak) UILabel *statusLabel;
@property (nonatomic, weak) UIBarButtonItem *trashButton;
@property (nonatomic, weak) UIBarButtonItem *locationButton;

@property (nonatomic) BOOL shouldMoveToNextUserLocation;

@end

@implementation FJTLocationViewController

- (id)initWithPlacemark:(CLPlacemark *)placemark
{
    if ( self = [super initWithNibName:nil bundle:nil] ) {
        [self setPlacemark:placemark];

        [self setHidesBottomBarWhenPushed:YES];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self setTitle:@"Set Location"];
    
    [self setupToolbar];
    
    [self setupMapView];
    
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    // [self.view setBackgroundColor:[UIColor orangeColor]];
    // [self.view.layer setBorderColor:[UIColor purpleColor].CGColor];
    // [self.view.layer setBorderWidth:2.0f];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateStatusLabel];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)setupToolbar
{
    UIBarButtonItem *tmpTrashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashButtonPressed:)];
    
    UIBarButtonItem *tmpFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UILabel *tmpStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 30.0f)];
    [tmpStatusLabel setTextAlignment:NSTextAlignmentCenter];
    [tmpStatusLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [tmpStatusLabel setNumberOfLines:1];
    [tmpStatusLabel setBackgroundColor:[UIColor clearColor]];
    UIBarButtonItem *tmpStatusItem = [[UIBarButtonItem alloc] initWithCustomView:tmpStatusLabel];

    UIBarButtonItem *tmpLocationButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"location"] style:UIBarButtonItemStylePlain target:self action:@selector(locationButtonPressed:)];
    
    [self setToolbarItems:@[tmpTrashButton, tmpFlexibleSpace, tmpStatusItem, tmpFlexibleSpace, tmpLocationButton]];

    [self setTrashButton:tmpTrashButton];
    [self setLocationButton:tmpLocationButton];
    [self setStatusLabel:tmpStatusLabel];
}

- (void)setupMapView
{
    if ( !self.mapView ) {
        MKMapView *tmpMapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
        [tmpMapView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth)];
        [self.view addSubview:tmpMapView];
        [tmpMapView setDelegate:self];
        [self setMapView:tmpMapView];
        
        
        UILongPressGestureRecognizer *tmpLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerFired:)];
        [self.mapView addGestureRecognizer:tmpLongPressGestureRecognizer];
        
    }
}

- (void)updateStatusLabel
{
    NSString *tmpStatusLabelText = @"LOL WUT";
    
    if ( self.pinPointAnnotation ) {
        if ( self.pinPlacemark ) {
            // TODO: show address from placemark
            tmpStatusLabelText = [NSString stringWithFormat:@"%@", self.pinPlacemark];
        } else {
            tmpStatusLabelText = @"Loading...";
        }
    }else {
        tmpStatusLabelText = @"No Location Set";
    }
    
    self.statusLabel.text = tmpStatusLabelText;
}

- (void)dropPinAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    MKPointAnnotation *tmpPinPointAnnotation = [[MKPointAnnotation alloc] init];
    [tmpPinPointAnnotation setCoordinate:coordinate];
    [self.mapView addAnnotation:tmpPinPointAnnotation];
    [self setPinPointAnnotation:tmpPinPointAnnotation];
    
    [self updatePinPlacemark];
    
    // TODO: start reverse geocoder for location
    [self updateStatusLabel];
}

- (void)updatePinPlacemark
{
    if ( self.pinPointAnnotation ) {
        
        [self setPinPlacemark:nil];
        
        self.statusLabel.text = @"Updating...";
        
        CLGeocoder *tmpGeocoder = [[CLGeocoder alloc] init];
        [tmpGeocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:self.pinPointAnnotation.coordinate.latitude longitude:self.pinPointAnnotation.coordinate.longitude]
                          completionHandler:^(NSArray *placemarks, NSError *error) {
                              if ( error ) {
                                  self.statusLabel.text = @"Error";
                              } else {
                                  [self setPinPlacemark:placemarks.firstObject];
                                  [self updateStatusLabel];
                              }
                          }];
        
    }
}

- (void)longPressGestureRecognizerFired:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if ( gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // NSLog(@"UILongPressGestureRecognizer Began");
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        if ( !self.pinPointAnnotation ) {
            [self dropPinAtCoordinate:touchMapCoordinate];
        }
    }
    
    return;
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
    if ( self.pinAnnotationView ) {
        [self.mapView removeAnnotation:self.pinPointAnnotation];
        [self setPinPointAnnotation:nil];
        [self updateStatusLabel];
    }
}

- (void)locationButtonPressed:(id)sender
{
    [self.mapView setShowsUserLocation:!self.mapView.showsUserLocation];
    
    [self.locationButton setImage:self.mapView.showsUserLocation?[UIImage imageNamed:@"location-on"]:[UIImage imageNamed:@"location"]];
    
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

@end
