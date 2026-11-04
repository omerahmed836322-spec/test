#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSData *LSOfflineActivationCopyReceipt(void);
FOUNDATION_EXPORT BOOL LSOfflineActivationRestoreReceipt(NSData *receipt);
FOUNDATION_EXPORT BOOL LSOfflineActivationReceiptIsValid(void);
FOUNDATION_EXPORT BOOL LSOfflineActivationVerifyCode(NSString *code);
FOUNDATION_EXPORT NSData *LSOfflineActivationExpectedReceipt(void);
