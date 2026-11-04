#import "LSWirelessSafety.h"
#import <dlfcn.h>
BOOL LSBluetoothHostHasPurposeString(void) {
    id value=NSBundle.mainBundle.infoDictionary[@"NSBluetoothAlwaysUsageDescription"];
    return [value isKindOfClass:NSString.class] && [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length>0;
}
NSString *LSBluetoothMissingPurposeMessage(void) { return @"التطبيق المضيف لا يحتوي NSBluetoothAlwaysUsageDescription في Info.plist. لم يبدأ الاتصال لتجنب إنهاء iOS للتطبيق؛ المحفوظات تبقى متاحة."; }
BOOL LSHostHasWiFiEntitlement(void) {
    typedef CFTypeRef (*Create)(CFAllocatorRef);
    typedef CFTypeRef (*Copy)(CFTypeRef,CFStringRef,CFErrorRef *);
    Create create=(Create)dlsym(RTLD_DEFAULT,"SecTaskCreateFromSelf");
    Copy copy=(Copy)dlsym(RTLD_DEFAULT,"SecTaskCopyValueForEntitlement");
    if(!create || !copy) return NO;
    CFTypeRef task=create(kCFAllocatorDefault); if(!task)return NO;
    CFTypeRef value=copy(task,CFSTR("com.apple.developer.networking.wifi-info"),NULL);
    BOOL yes=value && CFGetTypeID(value)==CFBooleanGetTypeID() && CFBooleanGetValue((CFBooleanRef)value);
    if(value)CFRelease(value); CFRelease(task); return yes;
}
