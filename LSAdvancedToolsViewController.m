#import "LSAdvancedToolsViewController.h"
#import "PersistenceManager.h"
#import "BookmarksManager.h"
#import "ImageSpoofingManager.h"
#import "LSInputValidation.h"
#import "LSGeoMath.h"
#import "RouteSimulator.h"
#import "LSImageOverlay.h"
#import "XsGpS.h"
#import "MapPickerViewController+Private.h"
@interface LSAdvancedToolsViewController ()
@property (nonatomic, assign) NSInteger toolSection;
@property (nonatomic, strong) NSTimer *refreshTimer;
@end
@implementation LSAdvancedToolsViewController
- (instancetype)initWithSection:(NSInteger)section {
    if((self=[super initWithStyle:UITableViewStyleInsetGrouped])) _toolSection=section;
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    self.view.semanticContentAttribute=UISemanticContentAttributeForceRightToLeft;
    self.title=@[@"إحداثيات الموقع",@"الحركة بالأمتار",@"الصورة والعدسات"][MAX(0,MIN(2,self.toolSection))];
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"رجوع" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"إغلاق" style:UIBarButtonItemStyleDone target:self action:@selector(closeAll)];
    self.navigationController.navigationBar.prefersLargeTitles=NO;
    self.tableView.rowHeight=UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight=66;
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    __weak typeof(self) weakSelf=self;
    self.refreshTimer=[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(__unused NSTimer *timer) {
        if(!weakSelf.presentedViewController)[weakSelf.tableView reloadData];
    }];
}
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated];[self.refreshTimer invalidate];self.refreshTimer=nil; }
- (void)close { if(self.onChanged)self.onChanged();[self.navigationController dismissViewControllerAnimated:YES completion:nil]; }
- (void)closeAll {
    UIViewController *main=self.navigationController.presentingViewController;
    if(self.onChanged)self.onChanged();
    [self.navigationController dismissViewControllerAnimated:NO completion:^{
        if([main respondsToSelector:NSSelectorFromString(@"ls_dismissToolPanelAnimatedDown")]) [(MapPickerViewController *)main ls_dismissToolPanelAnimatedDown];
        else [main dismissViewControllerAnimated:YES completion:nil];
    }];
}
- (void)changed { if(self.onChanged)self.onChanged();[self.tableView reloadData]; }
- (void)message:(NSString *)message {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"XsGpS" message:message preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"حسنًا" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
- (NSArray<NSString *> *)rowTitles {
    if(self.toolSection==0)return @[@"إدخال خط العرض والطول",@"لصق زوج الإحداثيات",@"عرض الموقع على الخريطة",@"تطبيق الموقع",@"حفظ الموقع باسم"];
    if(self.toolSection==1)return @[@"تفعيل التذبذب حول الموقع",@"نصف قطر الحركة بالمتر",@"مدة الانتقال بين النقاط",@"إعداد مشي: مسافة وسرعة واتجاه",@"بدء المشي",@"إيقاف مؤقت / استكمال",@"إيقاف المشي هنا",@"الرجوع إلى نقطة البداية"];
    return @[@"تفعيل استبدال الصورة",@"العدسة المستهدفة",@"رفع صورة مشتركة للعدستين",@"رفع صورة للأمامية",@"رفع صورة للخلفية",@"معاينة عائمة قابلة للتحريك",@"إخفاء المعاينة العائمة",@"حذف الصور المختارة",@"حالة آخر التقاط"];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {return self.rowTitles.count;}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(self.toolSection==0)return @"العرض من −90 إلى 90، والطول من −180 إلى 180. مثال: 24.7136, 46.6753. يدعم الأرقام العربية والإحداثيات السالبة.";
    if(self.toolSection==1)return @"التذبذب يبقى ضمن نصف القطر، والمشي خط مستقيم محاكى وليس مسار طرق. البدء أو الرجوع يوقف المسار الجاري. لا ضمان للتنفيذ أثناء تعليق التطبيق في الخلفية.";
    return @"استبدال صورة ثابتة عبر AVCapturePhotoOutput؛ ليس فيديو حيًا. المعاينة العائمة عرض مستقل لا يبدل بث الكاميرا. الصورة الخاصة بالعدسة تتقدم على المشتركة، ولا ضمان لواجهات تصوير أخرى.";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text=self.rowTitles[indexPath.row];cell.textLabel.numberOfLines=0;
    cell.detailTextLabel.numberOfLines=0;cell.detailTextLabel.textColor=UIColor.secondaryLabelColor;
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    PersistenceManager *store=[PersistenceManager shared];ImageSpoofingManager *image=[ImageSpoofingManager sharedManager];
    if(self.toolSection==0)cell.detailTextLabel.text=self.hasSelectedCoordinate ? [NSString stringWithFormat:@"%.6f, %.6f",self.selectedCoordinate.latitude,self.selectedCoordinate.longitude] : @"لم تحدد موقعًا";
    if(self.toolSection==1) {
        if(indexPath.row==0)cell.detailTextLabel.text=store.fluctuationEnabled ? @"مفعّل" : @"متوقف";
        if(indexPath.row==1)cell.detailTextLabel.text=[NSString stringWithFormat:@"%.1f متر",store.fluctuationRadius];
        if(indexPath.row==2)cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ ثانية",[store objectForKey:@"LSMovementInterval"] ?: @10];
        if(indexPath.row>=3)cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ م • %@ كم/س • %@° — %@",[store objectForKey:@"LSWalkDistance"] ?: @100,[store objectForKey:@"LSWalkSpeed"] ?: @5,[store objectForKey:@"LSWalkHeading"] ?: @0,LSRouteSimulator.shared.isPaused ? @"مؤقت" : LSRouteSimulator.shared.isSimulating ? @"جارٍ" : @"متوقف"];
    }
    if(self.toolSection==2) {
        if(indexPath.row==0)cell.detailTextLabel.text=image.referenceEnabled ? @"مفعّل" : @"متوقف";
        if(indexPath.row==1)cell.detailTextLabel.text=image.captureTarget==AVCaptureDevicePositionFront ? @"أمامية" : image.captureTarget==AVCaptureDevicePositionBack ? @"خلفية" : @"الاثنتان";
        if(indexPath.row==8){cell.detailTextLabel.text=image.lastCaptureStatus;cell.accessoryType=UITableViewCellAccessoryNone;}
    }
    return cell;
}
- (void)editCoordinatesCombined:(BOOL)combined {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:combined ? @"لصق الإحداثيات" : @"إحداثيات الموقع" message:@"ترتيب القيم: خط العرض ثم خط الطول." preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=combined ? @"24.7136, 46.6753" : @"خط العرض Latitude";f.keyboardType=UIKeyboardTypeNumbersAndPunctuation;f.textAlignment=NSTextAlignmentLeft;if(self.hasSelectedCoordinate)f.text=combined ? [NSString stringWithFormat:@"%.6f, %.6f",self.selectedCoordinate.latitude,self.selectedCoordinate.longitude] : [NSString stringWithFormat:@"%.6f",self.selectedCoordinate.latitude];}];
    if(!combined)[a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"خط الطول Longitude";f.keyboardType=UIKeyboardTypeNumbersAndPunctuation;f.textAlignment=NSTextAlignmentLeft;if(self.hasSelectedCoordinate)f.text=[NSString stringWithFormat:@"%.6f",self.selectedCoordinate.longitude];}];
    [a addAction:[UIAlertAction actionWithTitle:@"حفظ الاختيار" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
        CLLocationCoordinate2D c;BOOL valid=NO;
        if(combined)valid=LSParseCoordinatePair(a.textFields[0].text,&c);
        else {NSNumber *lat=LSParseFiniteNumber(a.textFields[0].text),*lon=LSParseFiniteNumber(a.textFields[1].text);c=CLLocationCoordinate2DMake(lat.doubleValue,lon.doubleValue);valid=lat && lon && CLLocationCoordinate2DIsValid(c);}
        if(!valid){[self message:@"أدخل إحداثيات صحيحة ضمن الحدود، دون نص إضافي."];return;}
        self.selectedCoordinate=c;self.hasSelectedCoordinate=YES;
        [[PersistenceManager shared] setObject:@[@(c.latitude),@(c.longitude)] forKey:@"LSManualCoordinate"];
        if(self.onCoordinate)self.onCoordinate(c,NO);[self changed];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
- (void)editNumber:(NSString *)title key:(NSString *)key initial:(double)initial min:(double)minimum max:(double)maximum radius:(BOOL)radius {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:@"القيمة بين %.0f و%.0f",minimum,maximum] preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.text=[NSString stringWithFormat:@"%.1f",initial];f.keyboardType=UIKeyboardTypeDecimalPad;}];
    [a addAction:[UIAlertAction actionWithTitle:@"حفظ" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
        NSNumber *v=LSParseFiniteNumber(a.textFields.firstObject.text);
        if(!v || v.doubleValue<minimum || v.doubleValue>maximum){[self message:@"القيمة غير صحيحة أو خارج النطاق."];return;}
        if(radius)[PersistenceManager shared].fluctuationRadius=v.doubleValue;
        else [[PersistenceManager shared] setObject:v forKey:key];[self changed];
    }]];[a addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
- (void)editWalk {
    PersistenceManager *s=[PersistenceManager shared];
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"إعداد المشي" message:@"مسافة 1–50000 متر، سرعة 1–300 كم/س، اتجاه 0–359.99 درجة. 0 شمال، 90 شرق." preferredStyle:UIAlertControllerStyleAlert];
    NSArray *keys=@[@"LSWalkDistance",@"LSWalkSpeed",@"LSWalkHeading"],*defaults=@[@100,@5,@0],*titles=@[@"المسافة بالمتر",@"السرعة كم/س",@"الاتجاه بالدرجة"];
    for(NSUInteger i=0;i<3;i++)[a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=titles[i];f.text=[[s objectForKey:keys[i]] ?: defaults[i] description];f.keyboardType=UIKeyboardTypeDecimalPad;}];
    [a addAction:[UIAlertAction actionWithTitle:@"حفظ" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
        NSNumber *d=LSParseFiniteNumber(a.textFields[0].text),*v=LSParseFiniteNumber(a.textFields[1].text),*h=LSParseFiniteNumber(a.textFields[2].text);
        if(!d||!v||!h||d.doubleValue<1||d.doubleValue>50000||v.doubleValue<1||v.doubleValue>300||h.doubleValue<0||h.doubleValue>=360){[self message:@"تحقق من المسافة والسرعة والاتجاه."];return;}
        [s setObject:d forKey:keys[0]];[s setObject:v forKey:keys[1]];[s setObject:h forKey:keys[2]];[self changed];
    }]];[a addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
- (BOOL)requireCoordinate {if(!self.hasSelectedCoordinate||!CLLocationCoordinate2DIsValid(self.selectedCoordinate)){[self message:@"حدد الموقع من الخريطة أو أدخل إحداثياته أولًا."];return NO;}return YES;}
- (void)startWalk {
    if(![self requireCoordinate])return;
    PersistenceManager *s=[PersistenceManager shared];
    double distance=[[s objectForKey:@"LSWalkDistance"] ?: @100 doubleValue],speed=[[s objectForKey:@"LSWalkSpeed"] ?: @5 doubleValue],heading=[[s objectForKey:@"LSWalkHeading"] ?: @0 doubleValue];
    if(!isfinite(distance)||distance<1||distance>50000||!isfinite(speed)||speed<1||speed>300||!isfinite(heading)||heading<0||heading>=360){[self message:@"أعد ضبط إعدادات المشي."];return;}
    [s setObject:@[@(self.selectedCoordinate.latitude),@(self.selectedCoordinate.longitude)] forKey:@"LSWalkOrigin"];
    LSGeoPoint end=LSGeoDestination((LSGeoPoint){self.selectedCoordinate.latitude,self.selectedCoordinate.longitude},distance,heading);
    // Intermediate geodesic points reduce distortion for long north/south paths.
    CLLocationCoordinate2D points[33];
    for(NSUInteger i=0;i<33;i++){LSGeoPoint p=LSGeoDestination((LSGeoPoint){self.selectedCoordinate.latitude,self.selectedCoordinate.longitude},distance*i/32.0,heading);points[i]=CLLocationCoordinate2DMake(p.latitude,p.longitude);}
    (void)end;
    LSRouteSimulator *sim=LSRouteSimulator.shared;sim.delegate=nil;sim.transportMode=LSTransportModeCustom;sim.customSpeedKmh=speed;
    [s setSpoofCoordinate:self.selectedCoordinate enabled:YES];s.fluctuationEnabled=NO;s.simulationWasActive=YES;LSSetHooksBypassed(NO);
    [sim startWithPolyline:[MKPolyline polylineWithCoordinates:points count:33]];[self changed];
}
- (void)chooseImage:(AVCaptureDevicePosition)position {
    ImageSpoofingManager *m=ImageSpoofingManager.sharedManager;m.editingPosition=position;
    __weak typeof(self) weakSelf=self;
    m.completionHandler=^(__unused UIImage *image){[weakSelf changed];ImageSpoofingManager.sharedManager.completionHandler=nil;};
    [m openPhotoLibraryFromViewController:self];
}
- (void)chooseLens {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"استبدال صورة أي عدسة؟" message:@"لا يغير هذا اختيار عدسة التطبيق نفسه." preferredStyle:UIAlertControllerStyleAlert];
    NSArray *titles=@[@"الاثنتان",@"أمامية",@"خلفية"],*positions=@[@(AVCaptureDevicePositionUnspecified),@(AVCaptureDevicePositionFront),@(AVCaptureDevicePositionBack)];
    for(NSUInteger i=0;i<3;i++)[a addAction:[UIAlertAction actionWithTitle:titles[i] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){ImageSpoofingManager.sharedManager.captureTarget=[positions[i] integerValue];[self changed];}]];
    [a addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];NSInteger row=indexPath.row;
    PersistenceManager *s=[PersistenceManager shared];ImageSpoofingManager *m=ImageSpoofingManager.sharedManager;
    if(self.toolSection==0) {
        if(row<2){[self editCoordinatesCombined:row==1];return;}
        if(![self requireCoordinate])return;
        if(row==2||row==3){if(self.onCoordinate)self.onCoordinate(self.selectedCoordinate,row==3);[self close];return;}
        UIAlertController *a=[UIAlertController alertControllerWithTitle:@"اسم الموقع" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"اسم للمحفوظات";}];
        [a addAction:[UIAlertAction actionWithTitle:@"حفظ" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){NSString *name=[a.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(!name.length){[self message:@"أدخل اسمًا للموقع."];return;}[BookmarksManager.shared addBookmarkWithName:name coordinate:self.selectedCoordinate];[self changed];}]];
        [a addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];return;
    }
    if(self.toolSection==1) {
        if(row==0){if(![self requireCoordinate])return;if(!s.fluctuationEnabled){[LSRouteSimulator.shared stop];s.simulationWasActive=NO;[s setSpoofCoordinate:self.selectedCoordinate enabled:YES];LSSetHooksBypassed(NO);}s.fluctuationEnabled=!s.fluctuationEnabled;[self changed];return;}
        if(row==1){[self editNumber:@"نصف القطر بالمتر" key:nil initial:s.fluctuationRadius min:1 max:5000 radius:YES];return;}
        if(row==2){[self editNumber:@"مدة الانتقال بالثواني" key:@"LSMovementInterval" initial:[[s objectForKey:@"LSMovementInterval"] ?: @10 doubleValue] min:1 max:120 radius:NO];return;}
        if(row==3){[self editWalk];return;}
        if(row==4){[self startWalk];return;}
        LSRouteSimulator *sim=LSRouteSimulator.shared;
        if(row==5){if(sim.isPaused)[sim resume];else if(sim.isSimulating)[sim pause];else [self message:@"لا توجد محاكاة مشي أو مسار جارٍ."];[self changed];return;}
        if(row==6){if(sim.isSimulating||sim.isPaused){CLLocationCoordinate2D current=sim.currentCoordinate;[sim stop];[s setSpoofCoordinate:current enabled:YES];s.simulationWasActive=NO;self.selectedCoordinate=current;self.hasSelectedCoordinate=YES;}[self changed];return;}
        NSArray *origin=[s objectForKey:@"LSWalkOrigin"];
        if(![origin isKindOfClass:NSArray.class]||origin.count!=2){[self message:@"لم تُحفظ نقطة بداية للمشي بعد."];return;}
        CLLocationCoordinate2D c=CLLocationCoordinate2DMake([origin[0] doubleValue],[origin[1] doubleValue]);
        if(!CLLocationCoordinate2DIsValid(c))return;
        [sim stop];s.fluctuationEnabled=NO;s.simulationWasActive=NO;[s setSpoofCoordinate:c enabled:YES];self.selectedCoordinate=c;self.hasSelectedCoordinate=YES;if(self.onCoordinate)self.onCoordinate(c,NO);[self changed];return;
    }
    if(row==0){if(![m getSelectedImage]){[self message:@"اختر صورة أولًا."];return;}m.referenceEnabled=!m.referenceEnabled;[self changed];return;}
    if(row==1){[self chooseLens];return;}
    if(row>=2&&row<=4){[self chooseImage:row==3?AVCaptureDevicePositionFront:row==4?AVCaptureDevicePositionBack:AVCaptureDevicePositionUnspecified];return;}
    if(row==5){if(![m getSelectedImage]){[self message:@"لا توجد صورة لعرضها."];return;}void(^show)(void)=self.onShowOverlay;[self.navigationController dismissViewControllerAnimated:YES completion:^{if(show)show();}];return;}
    if(row==6){[[LSImageOverlay shared] hide];return;}
    if(row==7){UIAlertController *a=[UIAlertController alertControllerWithTitle:@"حذف جميع الصور؟" message:@"يشمل الصورة المشتركة وصورتي العدستين." preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"حذف" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action){[m clearSelectedImage];[[LSImageOverlay shared] hide];[self changed];}]];[a addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];}
}
@end
