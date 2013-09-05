

#import "pARkViewController.h"
#import "PlaceOfInterest.h"
#import "ARView.h"

#import <CoreLocation/CoreLocation.h>

@implementation pARkViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)closeWindow:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)goToLocation{
    NSLog(@"Button clicked");
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	ARView *arView = (ARView *)self.view;
	
	// Create array of hard-coded places-of-interest, in this case some famous parks
    const char *poiNames[] = {"Central Park NY",
                              "Golden Gate Park SF",
                              "Balboa Park SD",
                              "Hyde Park UK",
                              "Mont Royal QC",
                              "Retiro Park ES"};
	
    CLLocationCoordinate2D poiCoords[] = {{40.7711329, -73.9741874},
                                          {37.7690400, -122.4835193},
                                          {32.7343822, -117.1441227},
                                          {51.5068670, -0.1708030},
                                          {45.5126399, -73.6802448},
                                          {40.4152519, -3.6887466}};
                                          
    int numPois = sizeof(poiCoords) / sizeof(CLLocationCoordinate2D);	
		
	NSMutableArray *placesOfInterest = [NSMutableArray arrayWithCapacity:numPois];
	for (int i = 0; i < numPois; i++) {
        
        UIButton *locationButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        locationButton.frame = CGRectMake(84, 150, 155, 50);
        [locationButton setBackgroundImage:[UIImage imageNamed:@"Button_active.png"] forState:UIControlStateNormal];
        [locationButton setBackgroundImage:[UIImage imageNamed:@"Button_active.png"] forState:UIControlStateHighlighted];
        [locationButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [locationButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        [locationButton setTitleShadowOffset:CGSizeMake(0.0, 1.0)];
        [locationButton setTitle:[NSString stringWithCString:poiNames[i] encoding:NSASCIIStringEncoding] forState:UIControlStateNormal];
        [locationButton addTarget:self action:@selector(goToLocation) forControlEvents:UIControlEventTouchUpInside];
        
        /**
		UILabel *label = [[[UILabel alloc] init] autorelease];
		label.adjustsFontSizeToFitWidth = NO;
		label.opaque = NO;
		label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
		label.center = CGPointMake(200.0f, 200.0f);
		label.textAlignment = NSTextAlignmentCenter;
		label.textColor = [UIColor whiteColor];
		label.text = [NSString stringWithCString:poiNames[i] encoding:NSASCIIStringEncoding];		
		CGSize size = [label.text sizeWithFont:label.font];
		label.bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
		*/		
         
		PlaceOfInterest *poi = [PlaceOfInterest placeOfInterestWithView:locationButton at:[[CLLocation alloc] initWithLatitude:poiCoords[i].latitude longitude:poiCoords[i].longitude]];
		[placesOfInterest insertObject:poi atIndex:i];
	}	
	[arView setPlacesOfInterest:placesOfInterest];	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	ARView *arView = (ARView *)self.view;
	[arView start];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	ARView *arView = (ARView *)self.view;
	[arView stop];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end
