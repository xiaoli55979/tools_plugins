//
//  RetrySessionManager.m
//  flutter_httpdns
//
//  Created by 阿浩 on 10/8/2024.
//

#import "SessionManager.h"
#import <AFNetworking/AFNetworking.h>
#import <MSDKDns_C11/MSDKDns.h>
#import "HTTPSWithSNIScenario.h"
#import "CacheManager.h"

@interface SessionManager()
@end

@implementation SessionManager

+ (instancetype)sharedInstance {
    static SessionManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SessionManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)httpDnsQueryWithURL:(NSString *)originalUrl argument:(NSDictionary *)argument completionHandler:(void(^)(NSString *message, NSURLResponse *response, NSError *error))completionHandler progress:(void(^)(NSString *url, NSError *error))progressHandler {
    if (!completionHandler) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    void(^handleCompletion)(NSString *, NSURLResponse *, NSError *, NSMutableURLRequest *) = ^(NSString *message, NSURLResponse *response, NSError *error, NSMutableURLRequest *backRequest) {
        if (error) {
            // 处理 API 失败重试
            [weakSelf retryDomainRequestArgument:argument completionHandler:^(NSString *message, NSURLResponse *response, NSError *error) {
                /// API也找不到的情况
                if (error == nil && [message length] == 0) {
                    // 处理 OSS 请求重试
                    [weakSelf retryOssRequestArgument:argument completionHandler:^(NSString *message, NSURLResponse *response, NSError *error) {
                        if (error) {
                            completionHandler(message, response, error);
                        } else {
                            completionHandler(message, response, nil);
                        }
                    } progress:progressHandler];
                } else {
                    completionHandler(message, response, nil);
                }
            } progress:progressHandler];
        } else {
            // 没有错误的情况
            completionHandler(message, response, nil);
        }
    };
    
    [HTTPSWithSNIScenario httpDnsQueryWithURL:originalUrl argument:argument request:nil completionHandler:handleCompletion];
}

/// API 线路重试
- (void)retryDomainRequestArgument:(NSDictionary *)argument completionHandler:(void(^)(NSString *message, NSURLResponse *response, NSError *error))completionHandler progress:(void(^)(NSString *url, NSError *error))progressHandler  {
    NSString *domainUrl = [[CacheManager sharedInstance] getNextDomainEndpointAtIndex:self.domainTryCount];
    if (domainUrl != nil) {
        NSString *appId = argument[@"appId"];
        NSString *url = [NSString stringWithFormat:@"https://%@/api/v1/app/%@/config/get", domainUrl, appId];

        [HTTPSWithSNIScenario httpDnsQueryWithURL:url argument:argument request:nil completionHandler:^(NSString *message, NSURLResponse *response, NSError *error, NSMutableURLRequest *backRequest) {
            self.domainTryCount++;
            if (error) {
                // 如果请求失败，调用 progressHandler 并继续重试
                if (progressHandler) {
                    progressHandler(url, error);
                }
                [self retryDomainRequestArgument:argument completionHandler:completionHandler progress:progressHandler]; // 递归重试
            } else {
                completionHandler(message, response, nil);
            }
        }];
    } else {
        // 如果没有更多的 domainUrl，调用完成处理并返回
        completionHandler(@"", [NSURLResponse new], nil);
    }
}

/// OSS 线路重试
- (void)retryOssRequestArgument:(NSDictionary *)argument completionHandler:(void(^)(NSString *message, NSURLResponse *response, NSError *error))completionHandler progress:(void(^)(NSString *url, NSError *error))progressHandler {
    NSString *ossUrl = [[CacheManager sharedInstance] getNextOssEndpointAtIndex:self.ossTryCount];
    if (ossUrl != nil) {
        [HTTPSWithSNIScenario httpDnsQueryWithURL:ossUrl argument:argument request:nil completionHandler:^(NSString *message, NSURLResponse *response, NSError *error, NSMutableURLRequest *backRequest) {
            self.ossTryCount++;
            if (error) {
                // 如果请求失败，调用 progressHandler 并继续重试
                if (progressHandler) {
                    progressHandler(ossUrl, error);
                }
                [self retryOssRequestArgument:argument completionHandler:completionHandler progress:progressHandler]; // 递归重试
            } else {
                completionHandler(message, response, nil);
            }
        }];
    } else {
        // 如果没有更多的 ossUrl，调用完成处理并返回
        completionHandler(@"", [NSURLResponse new], nil);
    }
}




@end

