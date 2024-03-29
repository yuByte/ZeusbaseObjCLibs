

#import "KMLViewerViewController.h"
#import "Config.h"

@implementation KMLViewerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Locate the path to the route.kml file in the application's bundle
    // and parse it with the KMLParser.
    NSString *path = [[NSBundle mainBundle] pathForResource:kmlFile ofType:kmlFileType];
    NSURL *url = [NSURL fileURLWithPath:path];
    kmlParser = [[KMLParser alloc] initWithURL:url];
    [kmlParser parseKML];
    
    // Add all of the MKOverlay objects parsed from the KML file to the map.
    NSArray *overlays = [kmlParser overlays];
    [map addOverlays:overlays];
    
    // Add all of the MKAnnotation objects parsed from the KML file to the map.
    NSArray *annotations = [kmlParser points];
    [map addAnnotations:annotations];
    
    // Walk the list of overlays and annotations and create a MKMapRect that
    // bounds all of them and store it into flyTo.
    MKMapRect flyTo = MKMapRectNull;
    for (id <MKOverlay> overlay in overlays) {
        if (MKMapRectIsNull(flyTo)) {
            flyTo = [overlay boundingMapRect];
        } else {
            flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
        }
    }
    
    for (id <MKAnnotation> annotation in annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(flyTo)) {
            flyTo = pointRect;
        } else {
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
    }
    
    // Position the map so that all overlays and annotations are visible on screen.
    map.visibleMapRect = flyTo;
}


- (void)viewDidUnload
{
 
    [super viewDidUnload];
}

#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [kmlParser viewForOverlay:overlay];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    return [kmlParser viewForAnnotation:annotation];
}

#pragma mark - Map View Functions
#pragma mark -

// Update current location when the user interacts with map
- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated
{
    current = [[CLLocation alloc] initWithLatitude:map.centerCoordinate.latitude longitude:map.centerCoordinate.longitude];
}




- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
	// Initialize each view
	for (MKPinAnnotationView *mkaview in views)
	{
        if (![mkaview isKindOfClass:[MKPinAnnotationView class]])
            continue;
        
        // Set the color to purple
        mkaview.pinColor = MKPinAnnotationColorGreen;
        mkaview.animatesDrop = true;
        
		// Add buttons to each one
		UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		mkaview.rightCalloutAccessoryView = button;
	}
}

-(IBAction)flipBackToController:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
