#import <UIKit/UIKit.h>
@interface LSImageOverlay : NSObject
+ (instancetype)shared;
- (void)showImage:(UIImage *)image;
- (void)hide;
@end
