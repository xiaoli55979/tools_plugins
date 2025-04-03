//
//  HttpDnsManager.m
//  flutter_httpdns
//
//  Created by 阿浩 on 10/8/2024.
//

#import "HttpDnsManager.h"
#import <MSDKDns_C11/MSDKDns.h>
#import <MSDKDns_C11/MSDKDnsHttpMessageTools.h>
#import "SessionManager.h"
#import "CacheManager.h"
#import "AESUtils.h"
#import "HttpConfig.h"
#import <CoreLocation/CoreLocation.h>
#import "HTTPSWithSNIScenario.h"

@interface HttpDnsManager() <CLLocationManagerDelegate,NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
/// 网络请求管理
@property (nonatomic, strong) SessionManager  *httpClient;
/// 缓存管理
@property (nonatomic, strong) CacheManager  *cacheManager;

@property (strong, nonatomic) NSURLConnection *connection;
@end

@implementation HttpDnsManager

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

+ (instancetype)sharedInstance {
    static HttpDnsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (SessionManager *)httpClient {
    if (_httpClient == NULL) {
        _httpClient = [SessionManager sharedInstance];
    }
    return  _httpClient;
}

- (CacheManager *)cacheManager {
    if (_cacheManager == NULL) {
        _cacheManager = [CacheManager sharedInstance];
    }
    return  _cacheManager;
}

// 初始化
- (void)initHttpsDns:(id)argument result:(FlutterResult)result {

    @try {        
        NSString *dnsId = argument[@"dnsId"];
        NSString *dnsKey = argument[@"dnsKey"];
        NSString *aesKey = argument[@"aesKey"];
        BOOL debug = [argument[@"debug"] boolValue];
        BOOL persistentCache = [argument[@"persistentCache"] boolValue];
        BOOL cachedIpEnable = [argument[@"cachedIpEnable"] boolValue];
        BOOL useExpiredIpEnable = [argument[@"useExpiredIpEnable"] boolValue];
        NSArray *defaultOssEndpoints = argument[@"defaultOss"];
        NSArray *defaultDomainEndpoints = argument[@"defaultDomains"];
        
        if (dnsId == nil || [dnsId isEqualToString:@""]) {
            @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                           reason:@"请填入dnsId"
                                         userInfo:nil];
        }
        
        if (dnsKey == nil || [dnsKey isEqualToString:@""]) {
            @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                           reason:@"请填入dnsKey"
                                         userInfo:nil];
        }
        
        // sdk初始化
        DnsConfig config = {
            .dnsId = [dnsId intValue],
            .dnsKey = dnsKey,
            .encryptType = HttpDnsEncryptTypeAES,
            .debug = debug,
        };
        [[MSDKDns sharedInstance] initConfig:&config];

        // 允许返回TTL过期域名的IP
        [[MSDKDns sharedInstance] WGSetExpiredIPEnabled:useExpiredIpEnable];
        /// 设置缓存
        [[MSDKDns sharedInstance] WGSetPersistCacheIPEnabled:persistentCache];
        /// dns预处理
        [[MSDKDns sharedInstance] WGSetPreResolvedDomains:defaultDomainEndpoints];
        
//        NSArray *getOssEndpoints = [self.cacheManager getOssEndpoints];
//        NSArray *getDomainEndpoints = [self.cacheManager getDomainEndpoints];

        
        // 线路缓存管理
        [self.cacheManager initEndpointsWithOssList:defaultOssEndpoints domains:defaultDomainEndpoints];

        self.httpClient.aesKey = aesKey;
        
        // 注册拦截请求的 NSURLProtocol
//        [NSURLProtocol registerClass:[MSDKDnsHttpMessageTools class]];
        // 如果成功，返回成功信息
        result(@"HttpsDns initialized successfully");
        
    } @catch (NSException *exception) {
        // 如果捕获到异常，返回错误信息
        result([FlutterError errorWithCode:exception.name
                                   message:exception.reason
                                   details:nil]);
    } @finally {
        NSLog(@"HttpsDns initialization process completed.");
    }
}

// 异步获取
- (void)getAddrByNameAsync:(id)argument result:(FlutterResult)resultCallback {
    NSString *domain = argument[@"domain"];
    [[MSDKDns sharedInstance] WGGetHostByNameAsync:domain returnIps:^(NSArray *ipsArray) {
        if (ipsArray != NULL) {
            resultCallback(ipsArray);
        } else {
            resultCallback([FlutterError errorWithCode:@"NO_RESULT" message:@"No result returned" details:nil]);
        }
    }];
}


// 异步获取 多个地址
- (void)getAddrsByNameAsync:(id)argument result:(FlutterResult)resultCallback {
    NSArray *domains = argument[@"domains"];
    [[MSDKDns sharedInstance] WGGetAllHostsByNamesAsync:domains returnIps:^(NSDictionary *ipsDictionary) {
        if (ipsDictionary != NULL) {
            resultCallback(ipsDictionary);
        } else {
            resultCallback([FlutterError errorWithCode:@"NO_RESULT" message:@"No result returned" details:nil]);
        }
    }];

}

// 获取配置
- (void)getConfig:(id)argument completion:(void (^)(NSDictionary *response, NSError * _Nullable error,NSString *url))completion {
    self.httpClient.domainTryCount = 0;
    self.httpClient.ossTryCount = 0;
    NSString *appId = argument[@"appId"];
    NSString *configKey = argument[@"configKey"];
    NSString *configHost = argument[@"configHost"];
    argument[@"aesKey"] = self.httpClient.aesKey;
    NSString *url = [NSString stringWithFormat:@"https://%@/api/v1/app/%@/config/get", configHost, appId];
    [self.httpClient  httpDnsQueryWithURL:url argument:argument completionHandler:^(NSString * _Nonnull message, NSURLResponse * response, NSError * _Nonnull error) {
        @try {
            
            NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonError;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
            if (error) {
                @try {
                    if(completion) {
                        completion([NSDictionary new], error,url);
                    }
                } @catch (NSException *exception) {
                    NSLog(@"exception:%@",exception);
                }
            } else {
                
                @try {
                    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *jsonDict = (NSDictionary *)jsonObject;
                        NSArray *ossEndpoints = jsonDict[@"oss"];
                        NSArray *domainEndpoints = jsonDict[@"domains"];
                        [self.cacheManager updateOssList:ossEndpoints];
                        [self.cacheManager updateDomains:domainEndpoints];
                        @try {
                            if(completion) {
                                completion(jsonDict,nil,url);
                            }
                        } @catch (NSException *exception) {
//                            NSLog(@"exception:%@",exception);
                        }
                    } else  {
                        
                        @try {
                            if(completion) {
                                completion([NSDictionary new],nil,url);
                            }
                        } @catch (NSException *exception) {
//                            NSLog(@"exception:%@",exception);
                        }
                        
                    }
                }
                @catch (NSException *exception) {
                    @try {
                        NSError *jsonError = [NSError errorWithDomain:@"ManagerErrorDomain" code:1002 userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
                        
                        completion([NSDictionary new], jsonError,url);
                    } @catch (NSException *exception) {
                        NSLog(@"exception:%@",exception);
                    }
                }

            }
        } @catch (NSException *exception) {
            if(completion) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: exception.reason};
                NSError *error = [NSError errorWithDomain:@"数据解析异常"
                                                     code:1001
                                                 userInfo:userInfo];
                completion([NSDictionary new],error,url);
            }
        }
    } progress:^(NSString * url, NSError * error) {
        @try {
            if (completion) {
                completion([NSDictionary new],error,url);
            }
        } @catch (NSException *exception) {
            NSLog(@"exception:%@",exception);
        }
    }];

}

// 清除缓存
- (void)clearAllCache {
    @try {
        
        [self.cacheManager clearAllCache];
        [[MSDKDns sharedInstance] clearCache];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

@end
