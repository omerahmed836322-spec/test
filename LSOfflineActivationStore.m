#import "LSOfflineActivationStore.h"
#import "LSOfflineVerifier.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
static NSMutableDictionary *LSReceiptQuery(void) {
    return [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:[@"com.xsgps.offline.activation." stringByAppendingString:NSBundle.mainBundle.bundleIdentifier ?: @"host"],
        (__bridge id)kSecAttrAccount:@"receipt-v1"} mutableCopy];
}
NSData *LSOfflineActivationExpectedReceipt(void) {
    NSMutableData *data = [NSMutableData dataWithBytes:LSOfflineSalt length:sizeof(LSOfflineSalt)];
    [data appendBytes:LSOfflineDigest length:sizeof(LSOfflineDigest)];
    return data;
}
NSData *LSOfflineActivationCopyReceipt(void) {
    NSMutableDictionary *q = LSReceiptQuery();
    q[(__bridge id)kSecReturnData] = @YES;
    q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)q, &result);
    return status == errSecSuccess ? CFBridgingRelease(result) : nil;
}
BOOL LSOfflineActivationRestoreReceipt(NSData *receipt) {
    if (![receipt isKindOfClass:NSData.class]) return NO;
    NSMutableDictionary *q = LSReceiptQuery();
    NSDictionary *attrs = @{(__bridge id)kSecValueData:receipt};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)q, (__bridge CFDictionaryRef)attrs);
    if (status == errSecItemNotFound) {
        q[(__bridge id)kSecValueData] = receipt;
        q[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
        status = SecItemAdd((__bridge CFDictionaryRef)q, NULL);
    }
    return status == errSecSuccess;
}
BOOL LSOfflineActivationReceiptIsValid(void) {
    return [LSOfflineActivationCopyReceipt() isEqualToData:LSOfflineActivationExpectedReceipt()];
}
BOOL LSOfflineActivationVerifyCode(NSString *code) {
    NSData *input = [code dataUsingEncoding:NSUTF8StringEncoding];
    if (!input.length || input.length > 512) return NO;
    unsigned char result[CC_SHA256_DIGEST_LENGTH] = {0};
    int status = CCKeyDerivationPBKDF(kCCPBKDF2, input.bytes, input.length, LSOfflineSalt, sizeof(LSOfflineSalt), kCCPRFHmacAlgSHA256, LSOfflineRounds, result, sizeof(result));
    unsigned char mismatch = 0;
    for (NSUInteger i=0;i<sizeof(result);i++) mismatch |= result[i] ^ LSOfflineDigest[i];
    memset(result, 0, sizeof(result));
    return status == kCCSuccess && mismatch == 0;
}
