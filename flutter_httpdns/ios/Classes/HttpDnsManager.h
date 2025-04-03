//
//  HttpDnsManager.h
//  flutter_httpdns
//
//  Created by 阿浩 on 10/8/2024.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface HttpDnsManager : NSObject

+ (instancetype)sharedInstance;

// 初始化
- (void)initHttpsDns:(id)argument result:(FlutterResult)result;
// 异步获取
- (void)getAddrByNameAsync:(id)argument result:(FlutterResult)result;
// 异步获取
- (void)getAddrsByNameAsync:(id)argument result:(FlutterResult)result;
// 异步获取
- (void)getConfig:(id)argument completion:(void (^)(NSDictionary *response, NSError * _Nullable error ,NSString *url))completion;
// 清除缓存
- (void)clearAllCache;
@end

NS_ASSUME_NONNULL_END
