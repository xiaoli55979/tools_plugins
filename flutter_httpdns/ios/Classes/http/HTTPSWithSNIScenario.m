//
//  HTTPSWithSNIScene.m
//  httpdns_ios_demo
//
//  Created by Miracle on 2024/5/24.
//  Copyright © 2024 alibaba. All rights reserved.
//

#import "HTTPSWithSNIScenario.h"
//#import <AlicloudHttpDNS/AlicloudHttpDNS.h>
#import "HttpDnsNSURLProtocolImpl.h"
#import <MSDKDns_C11/MSDKDns.h>
#import "HttpConfig.h"
#import "AESUtils.h"
#import "SessionManager.h"

@implementation HTTPSWithSNIScenario

+ (NSURLSession *)sharedUrlSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 3.0;
        configuration.timeoutIntervalForResource = 8.0;

        // 为了处理SNI问题，这里替换了NSURLProtocol的实现
        NSMutableArray *protocolsArray = [NSMutableArray arrayWithArray:configuration.protocolClasses];
        [protocolsArray insertObject:[HttpDnsNSURLProtocolImpl class] atIndex:0];
        [configuration setProtocolClasses:protocolsArray];

        session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    });
    return session;
}

+ (void)httpDnsQueryWithURL:(NSString *)originalUrl argument:(NSDictionary *)argument request:(NSMutableURLRequest * _Nullable)nrequest completionHandler:(void(^)(NSString *message, NSURLResponse *response, NSError *error,NSMutableURLRequest *backRequest))completionHandler {
    NSMutableURLRequest *request = nil;
    NSURL *url = [NSURL URLWithString:originalUrl];
    NSString *resolvedIpAddress = [self resolveAvailableIp:url.host];
    NSString *requestUrl = originalUrl;
    if (resolvedIpAddress) {
        // 通过HTTPDNS获取IP成功，进行URL替换和HOST头设置
        requestUrl = [originalUrl stringByReplacingOccurrencesOfString:url.host withString:resolvedIpAddress];
    }
    if ([self isJsonUrl:originalUrl]) {
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
        [request setValue:url.host forHTTPHeaderField:@"host"];
    } else {

        // 设置request
        request = [HttpConfig getRequestHost:requestUrl argument:argument isJson:NO];
        [request setValue:url.host forHTTPHeaderField:@"host"];
    }

    
    [self sendRequest:request completionHandler:^(NSString *message, NSURLResponse *response, NSError *error) {
        if (completionHandler) {
            completionHandler(message,response,error,request);
        }
    }];
}

+ (NSString *)resolveAvailableIp:(NSString *)host {
    @try {
        // 从 MSDKDns 获取所有的 IP 地址
        NSDictionary *resultHosts = [[MSDKDns sharedInstance] WGGetAllHostsByNames:@[host]];
        
        // 获取 IP 地址列表
        NSDictionary *hostData = resultHosts[host];
        NSMutableArray *ipAddresses = [NSMutableArray array];
        
        if (hostData) {
            NSArray *ipv4Addresses = hostData[@"ipv4"];
            NSArray *ipv6Addresses = hostData[@"ipv6"];
            
            // 将 IPv4 地址添加到 ipAddresses 中
            for (NSString *ipv4 in ipv4Addresses) {
                if (ipv4 && ([ipv4 integerValue] != 0)) {
                    [ipAddresses addObject:ipv4];
                }
            }
            
            // 将 IPv6 地址添加到 ipAddresses 中
            for (NSString *ipv6 in ipv6Addresses) {
                if (ipv6 && ([ipv6 integerValue] != 0)) {
                    [ipAddresses addObject:ipv6];
                }
            }
            
            if (ipAddresses.count > 0) {
                return ipAddresses.firstObject;
            } else {
                /// 未找到ip使用localDns
                return host;
            }
        }
        else {
            return nil;
        }

    } @catch (NSException *exception) {
        return nil;
    }
}

+ (void)sendRequest:(NSURLRequest *)request completionHandler:(void(^)(NSString * message,NSURLResponse *response, NSError *error))completionHandler {
    NSURLSession *session = [self sharedUrlSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSString *errorStr = [NSString stringWithFormat:@"Http request failed with error: %@", error];
            if (completionHandler) {
                completionHandler(@"",response,error);
            }
            return;
        }

        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger code = httpResponse.statusCode;
            NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            if (code == 200 && data != nil) {
                NSDictionary *headers = [httpResponse allHeaderFields];
                NSString *iv = headers[@"X-Sign"];
                NSString *decode = @"";
                if (iv == nil) {
                    decode = [AESUtils decryptText:dataStr withKey:[SessionManager sharedInstance].aesKey];
                } else {
                    decode = [AESUtils decryptWithText:dataStr key:[SessionManager sharedInstance].aesKey iv:iv];
                }
                if (decode != nil) {
                    completionHandler(decode,response,error);
                } else {
                    NSError *empterror = [NSError errorWithDomain:@""
                                                         code:code
                                                         userInfo:@{@"exception":dataStr}];
                    completionHandler(@"",response,empterror);
                }
            } else {
                NSError *empterror = [NSError errorWithDomain:@""
                                                     code:code
                                                     userInfo:@{@"exception":dataStr}];
                completionHandler(@"",response,empterror);
            }
        } else {
            completionHandler(@"",response,error);
        }
    }];
    [task resume];
}

+ (BOOL)isValidIPv4Address:(NSString *)ipAddress {
    NSString *ipv4Regex = @"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\."
                            @"(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\."
                            @"(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\."
                            @"(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    NSPredicate *ipv4Test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipv4Regex];
    return [ipv4Test evaluateWithObject:ipAddress];
}

+ (BOOL)isJsonUrl:(NSString *)url {
    if (url == nil) {
        return NO; // 或者根据需求处理 nil 的情况
    }
    return [url hasSuffix:@".json"];
}
@end
