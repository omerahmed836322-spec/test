#import "LSInputValidation.h"
#import <math.h>
static NSString *LSNormalizeNumbers(NSString *text) {
    NSMutableString *s=[text mutableCopy] ?: [NSMutableString string];
    NSArray *arabic=@[@"٠",@"١",@"٢",@"٣",@"٤",@"٥",@"٦",@"٧",@"٨",@"٩"];
    NSArray *persian=@[@"۰",@"۱",@"۲",@"۳",@"۴",@"۵",@"۶",@"۷",@"۸",@"۹"];
    for(NSUInteger i=0;i<10;i++) for(NSString *digit in @[arabic[i],persian[i]]) [s replaceOccurrencesOfString:digit withString:[NSString stringWithFormat:@"%lu",(unsigned long)i] options:0 range:NSMakeRange(0,s.length)];
    [s replaceOccurrencesOfString:@"٫" withString:@"." options:0 range:NSMakeRange(0,s.length)];
    [s replaceOccurrencesOfString:@"−" withString:@"-" options:0 range:NSMakeRange(0,s.length)];
    return [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}
NSNumber *LSParseFiniteNumber(NSString *text) {
    NSString *s=LSNormalizeNumbers(text);
    if(!s.length)return nil;
    NSScanner *scanner=[NSScanner scannerWithString:s];scanner.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    double value=0; return [scanner scanDouble:&value] && scanner.isAtEnd && isfinite(value) ? @(value) : nil;
}
BOOL LSParseCoordinatePair(NSString *text,CLLocationCoordinate2D *coordinate) {
    NSString *s=[LSNormalizeNumbers(text) stringByReplacingOccurrencesOfString:@"،" withString:@","];
    NSArray *parts=[s componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",;\n"]];
    NSMutableArray *nonempty=[NSMutableArray array];for(NSString *p in parts)if([p stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length)[nonempty addObject:p];
    if(nonempty.count!=2)return NO;
    NSNumber *lat=LSParseFiniteNumber(nonempty[0]),*lon=LSParseFiniteNumber(nonempty[1]);
    if(!lat||!lon)return NO;
    CLLocationCoordinate2D c=CLLocationCoordinate2DMake(lat.doubleValue,lon.doubleValue);
    if(!CLLocationCoordinate2DIsValid(c))return NO;if(coordinate)*coordinate=c;return YES;
}
