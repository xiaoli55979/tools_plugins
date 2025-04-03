//
//  AESUtils.m
//  flutter_httpdns
//
//  Created by 阿浩 on 12/8/2024.
//

#import "AESUtils.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation AESUtils

+ (NSString *)randomIV {
    NSString *charset = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *iv = [NSMutableString stringWithCapacity:16];
    for (int i = 0; i < 16; i++) {
        int randomIndex = arc4random_uniform((uint32_t)charset.length);
        [iv appendFormat:@"%C", [charset characterAtIndex:randomIndex]];
    }
    return iv;
}

+ (NSString *)encryptWithKey:(NSString *)key iv:(NSString *)iv text:(NSString *)text {
    if (!text || text.length == 0) {
        return text;
    }
    
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *encryptedData = [self AESOperation:kCCEncrypt data:data key:keyData iv:ivData];
    return [encryptedData base64EncodedStringWithOptions:0];
}

+ (NSString *)decryptWithText:(NSString *)text key:(NSString *)key {
    return [self decryptWithText:text key:key iv:nil];
}

+ (NSString *)decryptWithText:(NSString *)text key:(NSString *)key iv:(NSString *)iv {
//    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:text options:0];
    // 尝试解码 Base64 字符串
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:text options:NSDataBase64DecodingIgnoreUnknownCharacters];

    if (encryptedData) {
        NSLog(@"解码成功");
        // 继续处理 encryptedData
    } else {
        NSLog(@"解码失败，可能是字符串格式不正确");
    }
    
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = iv ? [iv dataUsingEncoding:NSUTF8StringEncoding] : [encryptedData subdataWithRange:NSMakeRange(0, 16)];
    
    NSData *decryptedData = [self AESOperation:kCCDecrypt data:encryptedData key:keyData iv:ivData];
    return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}

+ (NSData *)AESOperation:(CCOperation)operation data:(NSData *)data key:(NSData *)key iv:(NSData *)iv {
    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesProcessed = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [key bytes],
                                          kCCKeySizeAES256,
                                          [iv bytes],
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &numBytesProcessed);
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesProcessed];
    }
    
    free(buffer);
    return nil;
}

/// iv内置解密
+ (NSString *)decryptText:(NSString *)text withKey:(NSString *)key {
    @try {
        // 解码 Base64 字符串为 NSData
        NSData *content = [[NSData alloc] initWithBase64EncodedString:text options:0];
        
        // 调用解密方法
        NSData *decryptedData = [self decrypt:content withKey:key error:nil];
        
        if (decryptedData) {
            // 将解密后的数据转换为字符串
            return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
        } else {
            @throw [NSException exceptionWithName:@"DecryptionFailed" reason:@"解密失败" userInfo:nil];
        }
    } @catch (NSException *exception) {
        return nil;
    }
}

/// iv内置
+ (NSData *)decrypt:(NSData *)content withKey:(NSString *)key error:(NSError **)error {
    // 获取 IV（前16字节）
    NSData *iv = [content subdataWithRange:NSMakeRange(0, 16)];

    // 获取实际加密数据（从第17字节开始）
    NSData *body = [content subdataWithRange:NSMakeRange(16, content.length - 16)];

    // 创建AES秘钥
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];

    // 初始化解密器
    size_t bufferSize = [body length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          [keyData bytes], kCCKeySizeAES256,
                                          [iv bytes],
                                          [body bytes], [body length],
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    
    
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    } else {
        if (error) {
            *error = [NSError errorWithDomain:@"com.yourdomain.encryption" code:cryptStatus userInfo:nil];
        }
        free(buffer);
        return nil;
    }
}


@end

