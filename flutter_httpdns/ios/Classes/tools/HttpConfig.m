//
//  HttpConfig.m
//  flutter_httpdns
//
//  Created by 阿浩 on 13/8/2024.
//

#import "HttpConfig.h"
#import "AESUtils.h"

@implementation HttpConfig


//NSString *appId = argument[@"appId"];
//NSString *configKey = argument[@"configKey"];
//NSString *configHost = argument[@"configHost"];
//NSString *aesKey = argument[@"aesKey"];
+ (NSMutableURLRequest *)getRequestHost:(NSString *)host argument:(NSDictionary *)argument isJson:(BOOL)isJson {
    NSString *appId = argument[@"appId"];
    NSString *configKey = argument[@"configKey"];
    NSString *configHost = argument[@"configHost"];
    NSString *aesKey = argument[@"aesKey"];

//    if (appId == nil ) {
//        return  NULL;
//    }
//
//    if (configKey == nil || [configKey isEqualToString:@""]) {
//        return  NULL;
//    }
//
//    if (configHost == nil || [configHost isEqualToString:@""]) {
//        return  NULL;
//    }
//
//    if (aesKey == nil || [aesKey isEqualToString:@""]) {
//        return  NULL;
//    }
    
    NSString *url = [NSString stringWithFormat:@"https://%@/api/v1/app/%@/config/get", configHost, appId];
    if (host != nil) {
        url = host;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

    if (isJson) {
        [request setHTTPMethod:@"GET"];
        url = host;
    } else {
        [request setHTTPMethod:@"POST"];
    }

    if(!isJson) {
        // 设置请求头
        NSString *iv = [AESUtils randomIV];
        [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:iv forHTTPHeaderField:@"x-sign"];

        // 设置请求体
        NSError *error;
        NSString *payloadString = [self buildReqBodyWithConfigKey:configKey aesKey:aesKey iv:iv];
        if (error) {
            NSLog(@"Error creating JSON payload: %@", error.localizedDescription);
        } else {
            NSData *payloadData = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
            [request setHTTPBody:payloadData];
        }
    }
    return  request;
}

+ (NSString *)buildReqBodyWithConfigKey:(NSString *)configKey aesKey:(NSString *)aesKey iv:(NSString *)iv {
    @try {
        // 创建 JSON 对象
        NSDictionary *params = @{@"configKey": configKey};
        NSError *error;
        NSData *jsonDataConfig = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        
        if (!jsonDataConfig) {
            NSLog(@"Error serializing JSON: %@", error.localizedDescription);
            return @"";
        }
        
        NSString *paramsString = [[NSString alloc] initWithData:jsonDataConfig encoding:NSUTF8StringEncoding];
        
        // 使用 AESUtils 进行加密
        NSString *encodeData = [AESUtils encryptWithKey:aesKey iv:iv text:paramsString];

        
        // 创建请求体 JSON 对象
        NSDictionary *body = @{@"data": encodeData};
        // 将 NSDictionary 转换为 JSON 数据
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
        
        if (error) {
            NSLog(@"Error converting dictionary to JSON: %@", error.localizedDescription);
            return nil;
        }
        
        // 将 JSON 数据转换为 NSString
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception.reason);
        return @"";
    }
}


@end
