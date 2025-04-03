//
//  RetrySessionManager.h
//  flutter_httpdns
//
//  Created by 阿浩 on 10/8/2024.
//

#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface SessionManager : NSObject

/// api线路异常重试次数 时间根据本地线路数量来重试
@property (nonatomic, assign) NSInteger domainTryCount;
/// oss线路异常重试次数
@property (nonatomic, assign) NSInteger ossTryCount;

@property (nonatomic, copy) NSString  *aesKey;

+ (instancetype)sharedInstance;
- (void)httpDnsQueryWithURL:(NSString *)originalUrl argument:(NSDictionary *)argument completionHandler:(void(^)(NSString *message, NSURLResponse *response, NSError *error))completionHandler progress:(void(^)(NSString *url, NSError *error))progressHandler;
@end

NS_ASSUME_NONNULL_END
