#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
@interface LSAdvancedToolsViewController : UITableViewController
- (instancetype)initWithSection:(NSInteger)section;
@property (nonatomic, assign) CLLocationCoordinate2D selectedCoordinate;
@property (nonatomic, assign) BOOL hasSelectedCoordinate;
@property (nonatomic, copy) void (^onCoordinate)(CLLocationCoordinate2D coordinate, BOOL apply);
@property (nonatomic, copy) void (^onChanged)(void);
@property (nonatomic, copy) void (^onShowOverlay)(void);
@end
