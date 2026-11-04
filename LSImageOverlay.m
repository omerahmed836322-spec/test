#import "LSImageOverlay.h"
@interface XsGpSImageWindow : UIWindow @end
@implementation XsGpSImageWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit=[super hitTest:point withEvent:event];
    return hit==self.rootViewController.view || hit==self ? nil : hit;
}
@end
@interface XsGpSImageOverlayController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *lockButton;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) CGRect gestureStartFrame;
@property (nonatomic, copy) void (^onClose)(void);
- (void)clampPanel;
@end
@implementation XsGpSImageOverlayController
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.clearColor;
    self.panel=[[UIView alloc] initWithFrame:CGRectMake(20,80,220,260)];
    self.panel.backgroundColor=[UIColor colorWithWhite:0.06 alpha:0.95];self.panel.layer.cornerRadius=16;self.panel.clipsToBounds=YES;
    [self.view addSubview:self.panel];
    self.imageView=[UIImageView new];self.imageView.translatesAutoresizingMaskIntoConstraints=NO;
    self.imageView.contentMode=UIViewContentModeScaleAspectFit;[self.panel addSubview:self.imageView];
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];[close setTitle:@"إغلاق" forState:UIControlStateNormal];[close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    self.lockButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.lockButton setTitle:@"قفل" forState:UIControlStateNormal];[self.lockButton addTarget:self action:@selector(toggleLock) forControlEvents:UIControlEventTouchUpInside];
    UIButton *reset=[UIButton buttonWithType:UIButtonTypeSystem];[reset setTitle:@"حجم" forState:UIControlStateNormal];[reset addTarget:self action:@selector(resetSize) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *bar=[[UIStackView alloc] initWithArrangedSubviews:@[close,self.lockButton,reset]];bar.translatesAutoresizingMaskIntoConstraints=NO;bar.axis=UILayoutConstraintAxisHorizontal;bar.distribution=UIStackViewDistributionFillEqually;[self.panel addSubview:bar];
    [NSLayoutConstraint activateConstraints:@[
        [bar.topAnchor constraintEqualToAnchor:self.panel.topAnchor],[bar.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],[bar.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor],[bar.heightAnchor constraintEqualToConstant:44],
        [self.imageView.topAnchor constraintEqualToAnchor:bar.bottomAnchor],[self.imageView.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:4],[self.imageView.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-4],[self.imageView.bottomAnchor constraintEqualToAnchor:self.panel.bottomAnchor constant:-4]
    ]];
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];pan.delegate=self;[self.panel addGestureRecognizer:pan];
    UIPinchGestureRecognizer *pinch=[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];pinch.delegate=self;[self.panel addGestureRecognizer:pinch];
    NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"com.xsgps.dylib"];
    NSString *frame=[d stringForKey:@"LSReferenceOverlayFrame"];
    if(frame.length){CGRect r=CGRectFromString(frame);if(isfinite(r.origin.x)&&isfinite(r.origin.y)&&isfinite(r.size.width)&&isfinite(r.size.height))self.panel.frame=r;}
    self.locked=[d boolForKey:@"LSReferenceOverlayLocked"];[self updateLock];
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews];[self clampPanel]; }
- (void)clampPanel {
    UIEdgeInsets inset=self.view.safeAreaInsets;
    CGRect safe=UIEdgeInsetsInsetRect(self.view.bounds,UIEdgeInsetsMake(inset.top+8,inset.left+8,inset.bottom+8,inset.right+8));
    if(safe.size.width<=0||safe.size.height<=0)return;
    CGRect f=self.panel.frame;f.size.width=MIN(safe.size.width,MAX(160,f.size.width));f.size.height=MIN(safe.size.height,MAX(160,f.size.height));
    f.origin.x=MAX(CGRectGetMinX(safe),MIN(f.origin.x,CGRectGetMaxX(safe)-f.size.width));f.origin.y=MAX(CGRectGetMinY(safe),MIN(f.origin.y,CGRectGetMaxY(safe)-f.size.height));
    if(!CGRectEqualToRect(f,self.panel.frame))self.panel.frame=f;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    if(self.locked)return NO;for(UIView *v=touch.view;v && v!=self.panel;v=v.superview)if([v isKindOfClass:UIControl.class])return NO;return YES;
}
- (void)save {NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:@"com.xsgps.dylib"];[d setObject:NSStringFromCGRect(self.panel.frame) forKey:@"LSReferenceOverlayFrame"];[d setBool:self.locked forKey:@"LSReferenceOverlayLocked"];}
- (void)pan:(UIPanGestureRecognizer *)g {
    if(self.locked)return;if(g.state==UIGestureRecognizerStateBegan)self.gestureStartFrame=self.panel.frame;
    CGPoint delta=[g translationInView:self.view];CGRect f=self.gestureStartFrame;f.origin.x+=delta.x;f.origin.y+=delta.y;self.panel.frame=f;[self clampPanel];if(g.state==UIGestureRecognizerStateEnded)[self save];
}
- (void)pinch:(UIPinchGestureRecognizer *)g {
    if(self.locked)return;if(g.state==UIGestureRecognizerStateBegan)self.gestureStartFrame=self.panel.frame;
    CGRect f=self.gestureStartFrame;f.size.width*=g.scale;f.size.height*=g.scale;self.panel.frame=f;[self clampPanel];if(g.state==UIGestureRecognizerStateEnded)[self save];
}
- (void)resetSize {if(self.locked)return;CGRect f=self.panel.frame;f.size=CGSizeMake(220,260);self.panel.frame=f;[self clampPanel];[self save];}
- (void)updateLock {[self.lockButton setTitle:self.locked?@"فتح":@"قفل" forState:UIControlStateNormal];}
- (void)toggleLock {self.locked=!self.locked;[self updateLock];[self save];}
- (void)close {[self save];if(self.onClose)self.onClose();}
@end
@interface LSImageOverlay ()
@property (nonatomic, strong) XsGpSImageWindow *window;
@end
@implementation LSImageOverlay
+ (instancetype)shared {static LSImageOverlay *s;static dispatch_once_t once;dispatch_once(&once,^{s=[self new];});return s;}
- (void)showImage:(UIImage *)image {
    if(!image)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self showImage:image];});return;}
    [self hide];UIWindowScene *active=nil;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)if([scene isKindOfClass:UIWindowScene.class]&&scene.activationState==UISceneActivationStateForegroundActive){active=(UIWindowScene *)scene;break;}
    if(!active)return;
    self.window=[[XsGpSImageWindow alloc] initWithWindowScene:active];self.window.frame=active.coordinateSpace.bounds;
    self.window.backgroundColor=UIColor.clearColor;self.window.windowLevel=UIWindowLevelNormal+5;
    XsGpSImageOverlayController *vc=[XsGpSImageOverlayController new];__weak typeof(self) weakSelf=self;vc.onClose=^{[weakSelf hide];};
    self.window.rootViewController=vc;[vc loadViewIfNeeded];vc.imageView.image=image;
    self.window.hidden=NO; // Never makeKey: host app retains keyboard and key-window ownership.
}
- (void)hide {if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self hide];});return;}self.window.hidden=YES;self.window=nil;}
@end
