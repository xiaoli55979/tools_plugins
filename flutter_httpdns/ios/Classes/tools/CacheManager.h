//
//  CacheManager.h
//  flutter_httpdns
//
//  Created by 阿浩 on 12/8/2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CacheManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, assign) BOOL  cachedIpEnable;
// 线路缓存管理
- (void)initEndpointsWithOssList:(NSArray<NSString *> *)ossList domains:(NSArray<NSString *> *)domains;
- (void)updateOssList:(NSArray<NSString *> *)ossList;
- (void)updateDomains:(NSArray<NSString *> *)domains;
// 获取OSS可用线路
- (NSString *)getNextOssEndpointAtIndex:(NSInteger)index;

// 获取Domain可用线路
- (NSString *)getNextDomainEndpointAtIndex:(NSInteger)index;

- (NSArray<NSString *> *)getOssEndpoints;
- (NSArray<NSString *> *)getDomainEndpoints;
- (void)clearAllCache;
@end

NS_ASSUME_NONNULL_END
