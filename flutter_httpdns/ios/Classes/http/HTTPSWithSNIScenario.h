//
//  HTTPSWithSNIScene.h
//  httpdns_ios_demo
//
//  Created by Miracle on 2024/5/24.
//  Copyright © 2024 alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTTPSWithSNIScenario : NSObject

+ (void)httpDnsQueryWithURL:(NSString *)originalUrl argument:(NSDictionary *)argument request:(NSMutableURLRequest * _Nullable)nrequest completionHandler:(void(^)(NSString *message, NSURLResponse *response, NSError *error,NSMutableURLRequest *backRequest))completionHandler;

@end

NS_ASSUME_NONNULL_END
