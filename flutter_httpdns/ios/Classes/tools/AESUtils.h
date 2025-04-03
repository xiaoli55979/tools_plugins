//
//  AESUtils.h
//  flutter_httpdns
//
//  Created by 阿浩 on 12/8/2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface AESUtils : NSObject

+ (NSString *)randomIV;
+ (NSString *)encryptWithKey:(NSString *)key iv:(NSString *)iv text:(NSString *)text;
+ (NSString *)decryptWithText:(NSString *)text key:(NSString *)key;
+ (NSString *)decryptWithText:(NSString *)text key:(NSString *)key iv:(NSString *)iv;
+ (NSString *)decryptText:(NSString *)text withKey:(NSString *)key;
@end


NS_ASSUME_NONNULL_END
