//
//  HttpConfig.h
//  flutter_httpdns
//
//  Created by 阿浩 on 13/8/2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HttpConfig : NSObject
+ (NSMutableURLRequest *)getRequestHost:(NSString *)host argument:(NSDictionary *)argument isJson:(BOOL)isJson;
@end

NS_ASSUME_NONNULL_END
