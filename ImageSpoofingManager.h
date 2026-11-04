#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ImageCompletionHandler)(UIImage *image);

// مـدير تزييف الصور: يقوم بحفظ الصورة واعتراض كاميرا النظام (UIImagePickerController) داخل التطبيقات المستهدفة.
@interface ImageSpoofingManager : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

+ (instancetype)sharedManager;
@property (nonatomic, strong, nullable) UIImage *selectedImage;
@property (nonatomic, assign, getter=isReferenceEnabled) BOOL referenceEnabled;
@property (nonatomic, copy, nullable) ImageCompletionHandler completionHandler;

// Unspecified target means both lenses. Unspecified editingPosition chooses the common fallback image.
@property (nonatomic, assign) AVCaptureDevicePosition captureTarget;
@property (nonatomic, assign) AVCaptureDevicePosition editingPosition;
@property (nonatomic, copy) NSString *lastCaptureStatus;
- (nullable UIImage *)imageForCameraPosition:(AVCaptureDevicePosition)position;
- (void)recordCaptureID:(int64_t)captureID position:(AVCaptureDevicePosition)position;
- (AVCaptureDevicePosition)takePositionForCaptureID:(int64_t)captureID;
- (void)openPhotoLibraryFromViewController:(UIViewController *)viewController;
- (void)enableReference;
- (void)disableReference;
- (nullable UIImage *)getSelectedImage;
- (void)clearSelectedImage;

@end

NS_ASSUME_NONNULL_END
