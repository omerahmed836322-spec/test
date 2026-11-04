// Offline fixed-code lock; original server implementation remains in #else.
#import "LSActivationManager.h"
#import "LSOfflineActivationStore.h"
#import <UIKit/UIKit.h>
@interface LSActivationManager ()
@property (nonatomic, assign) BOOL offlineActivated;
@end
@implementation LSActivationManager
+ (instancetype)shared {
    static LSActivationManager *manager; static dispatch_once_t once;
    dispatch_once(&once, ^{ manager=[self new]; manager.offlineActivated=LSOfflineActivationReceiptIsValid(); });
    return manager;
}
+ (void)loadEarly { (void)[self shared]; }
- (BOOL)isActivated { return self.offlineActivated; }
- (NSString *)deviceIdentifier { return UIDevice.currentDevice.identifierForVendor.UUIDString ?: @"XSGPS-OFFLINE"; }
- (NSString *)subscriptionStatusText { return self.isActivated ? @"مفعّل — كود محلي" : @"يلزم كود التفعيل"; }
- (NSInteger)daysRemaining { return -1; }
- (NSDate *)expirationDate { return nil; }
- (NSString *)normalizedCodeFromString:(NSString *)string { return [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]; }
- (BOOL)activateWithCode:(NSString *)code errorMessage:(NSString **)errorMessage {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"com.xsgps.dylib"];
    double now=NSDate.date.timeIntervalSince1970, until=[d doubleForKey:@"LSOfflineRetryUntil"];
    if (until>now) { if(errorMessage)*errorMessage=@"محاولات كثيرة؛ انتظر دقيقة ثم حاول مجددًا."; return NO; }
    if (!LSOfflineActivationVerifyCode([self normalizedCodeFromString:code])) {
        NSInteger failures=[d integerForKey:@"LSOfflineFailures"]+1;
        [d setInteger:failures forKey:@"LSOfflineFailures"];
        if(failures>=5) { [d setDouble:now+60 forKey:@"LSOfflineRetryUntil"]; [d setInteger:0 forKey:@"LSOfflineFailures"]; }
        if(errorMessage)*errorMessage=@"كود التفعيل غير صحيح.";
        return NO;
    }
    if(!LSOfflineActivationRestoreReceipt(LSOfflineActivationExpectedReceipt())) {
        if(errorMessage)*errorMessage=@"تعذر حفظ التفعيل في Keychain للتطبيق المضيف. لم يتم التفعيل.";
        return NO;
    }
    self.offlineActivated=YES;
    [d removeObjectForKey:@"LSOfflineFailures"]; [d removeObjectForKey:@"LSOfflineRetryUntil"];
    if(errorMessage)*errorMessage=nil;
    return YES;
}
@end
