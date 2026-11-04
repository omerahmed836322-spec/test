#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
FOUNDATION_EXPORT NSNumber *LSParseFiniteNumber(NSString *text);
FOUNDATION_EXPORT BOOL LSParseCoordinatePair(NSString *text,CLLocationCoordinate2D *coordinate);
