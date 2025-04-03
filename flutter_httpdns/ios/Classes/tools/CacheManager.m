//
//  CacheManager.m
//  flutter_httpdns
//
//  Created by 阿浩 on 12/8/2024.
//

#import <Foundation/Foundation.h>
#import <YYCache/YYCache.h>

static NSString *const OSS_KEY = @"ossEndpoints";
static NSString *const DOMAIN_KEY = @"domainEndpoints";


@interface CacheManager : NSObject


- (void)saveData:(id<NSCoding>)data forKey:(NSString *)key;
- (id)getDataForKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;
- (void)clearAllCache;

@end

@implementation CacheManager {
    YYCache *_cache;
}

+ (instancetype)sharedInstance {
    static CacheManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CacheManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化缓存，设置缓存名称
        _cache = [YYCache cacheWithName:@"AppLinesCache"];
    }
    return self;
}

#pragma mark - 线路缓存
/// 初始化线路缓存
- (void)initEndpointsWithOssList:(NSArray<NSString *> *)ossList domains:(NSArray<NSString *> *)domains {
    if ([self isEmpty:[self getOssEndpoints]] && ![self isEmpty:ossList]) {
        [[CacheManager sharedInstance] saveData:ossList forKey:OSS_KEY];
    }
    if ([self isEmpty:[self getDomainEndpoints]] && ![self isEmpty:domains]) {
        [[CacheManager sharedInstance] saveData:domains forKey:DOMAIN_KEY];
    }
}

/// 更新oss线路
- (void)updateOssList:(NSArray<NSString *> *)ossList {
    if (ossList != nil && [ossList count] > 0) {
        [[CacheManager sharedInstance] saveData:ossList forKey:OSS_KEY];
    }
}

/// 更新api线路
- (void)updateDomains:(NSArray<NSString *> *)domains {
    if (domains != nil && [domains count] > 0) {
        [[CacheManager sharedInstance] saveData:domains forKey:DOMAIN_KEY];
    }
}


- (BOOL)isEmpty:(NSArray *)array {
    return (array == nil || array.count == 0);
}



// 获取OSS可用线路
- (NSString *)getNextOssEndpointAtIndex:(NSInteger)index {
    NSArray<NSString *> *cached = [self getOssEndpoints];
    if (cached == nil || cached.count <= index) {
        return nil;
    }
    return cached[index];
}

// 获取Domain可用线路
- (NSString *)getNextDomainEndpointAtIndex:(NSInteger)index {
    NSArray<NSString *> *cached = [self getDomainEndpoints];
    if (cached == nil || cached.count <= index) {
        return nil;
    }
    return cached[index];
}


- (NSArray<NSString *> *)getOssEndpoints {
    return [[CacheManager sharedInstance] getDataForKey:OSS_KEY];
}

- (NSArray<NSString *> *)getDomainEndpoints {
    return [[CacheManager sharedInstance] getDataForKey:DOMAIN_KEY];
}

#pragma mark - 缓存存取方法

// 保存数据到缓存
- (void)saveData:(id<NSCoding>)data forKey:(NSString *)key {
    [_cache setObject:data forKey:key];
}

// 从缓存获取数据
- (id)getDataForKey:(NSString *)key {
    return [_cache objectForKey:key];
}

// 删除缓存中的数据
- (void)removeDataForKey:(NSString *)key {
    [_cache removeObjectForKey:key];
}

// 清空所有缓存
- (void)clearAllCache {
    [_cache removeAllObjects];
}

@end


