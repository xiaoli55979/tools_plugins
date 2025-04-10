#import <Foundation/Foundation.h>
#import "HttpDnsNSURLProtocolImpl.h"
#import <arpa/inet.h>
#import <objc/runtime.h>

static NSString *const hasBeenInterceptedCustomLabelKey = @"HttpDnsHttpMessagePropertyKey";
static NSString *const kAnchorAlreadyAdded = @"AnchorAlreadyAdded";

@interface HttpDnsNSURLProtocolImpl () <NSStreamDelegate>

@property (strong, readwrite, nonatomic) NSMutableURLRequest *curRequest;
@property (strong, readwrite, nonatomic) NSRunLoop *curRunLoop;
@property (strong, readwrite, nonatomic) NSInputStream *inputStream;

@end

@implementation HttpDnsNSURLProtocolImpl

/**
 *  是否拦截处理指定的请求
 *
 *  @param request 指定的请求
 *  @return 返回YES表示要拦截处理，返回NO表示不拦截处理
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if([[request.URL absoluteString] isEqual:@"about:blank"]) {
        return NO;
    }

    // 防止无限循环，因为一个请求在被拦截处理过程中，也会发起一个请求，这样又会走到这里，如果不进行处理，就会造成无限循环
    if ([NSURLProtocol propertyForKey:hasBeenInterceptedCustomLabelKey inRequest:request]) {
        return NO;
    }

    NSString * url = request.URL.absoluteString;
    NSString * domain = request.URL.host;

    // 只有https需要拦截
    if (![url hasPrefix:@"https"]) {
        return NO;
    }

    // 需要的话可以做更多判断，如配置一个host数组来限制只有这个数组中的host才需要拦截

    // 只有已经替换为ip的请求需要拦截
    if (![self isPlainIpAddress:domain]) {
        return NO;
    }
    return YES;
}

+ (BOOL)isPlainIpAddress:(NSString *)hostStr {
    if (!hostStr) {
        return NO;
    }

    // 是否ipv4地址
    const char *utf8 = [hostStr UTF8String];
    int success = 0;
    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    if (success == 1) {
        return YES;
    }

    // 是否ipv6地址
    struct in6_addr dst6;
    success = inet_pton(AF_INET6, utf8, &dst6);
    if (success == 1) {
        return YES;
    }

    return NO;
}

// 如果需要对请求进行重定向，添加指定头部等操作，可以在该方法中进行
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

// 开始加载，在该方法中，加载一个请求
- (void)startLoading {
    NSMutableURLRequest *request = [self.request mutableCopy];
    // 表示该请求已经被处理，防止无限循环
    [NSURLProtocol setProperty:@(YES) forKey:hasBeenInterceptedCustomLabelKey inRequest:request];
    self.curRequest = [self createNewRequest:request];
    [self startRequest];
}

- (NSString *)cookieForURL:(NSURL *)URL {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableArray *cookieList = [NSMutableArray array];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if (![self p_checkCookie:cookie URL:URL]) {
            continue;
        }
        [cookieList addObject:cookie];
    }

    if (cookieList.count > 0) {
        NSDictionary *cookieDic = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieList];
        if ([cookieDic objectForKey:@"Cookie"]) {
            return cookieDic[@"Cookie"];
        }
    }
    return nil;
}


- (BOOL)p_checkCookie:(NSHTTPCookie *)cookie URL:(NSURL *)URL {
    if (cookie.domain.length <= 0 || URL.host.length <= 0) {
        return NO;
    }
    if ([URL.host containsString:cookie.domain]) {
        return YES;
    }
    return NO;
}

- (NSMutableURLRequest *)createNewRequest:(NSURLRequest*)request {
    NSURL* originUrl = request.URL;
    NSString *cookie = [self cookieForURL:originUrl];

    NSMutableURLRequest* mutableRequest = [request copy];
    [mutableRequest setValue:cookie forHTTPHeaderField:@"Cookie"];

    return [mutableRequest copy];
}

/**
 * 取消请求
 */
- (void)stopLoading {
    if (_inputStream.streamStatus == NSStreamStatusOpen) {
        [self closeStream:_inputStream];
    }
    [self.client URLProtocol:self didFailWithError:[[NSError alloc] initWithDomain:@"stop loading" code:-1 userInfo:nil]];
}

/**
 * 使用CFHTTPMessage转发请求
 */
- (void)startRequest {
    // 原请求的header信息
    NSDictionary *headFields = _curRequest.allHTTPHeaderFields;
    CFStringRef url = (__bridge CFStringRef) [_curRequest.URL absoluteString];
    CFURLRef requestURL = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);

    // 原请求所使用的方法，GET或POST
    CFStringRef requestMethod = (__bridge_retained CFStringRef) _curRequest.HTTPMethod;

    // 根据请求的url、方法、版本创建CFHTTPMessageRef对象
    CFHTTPMessageRef cfrequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, requestURL, kCFHTTPVersion1_1);

    // 添加http post请求所附带的数据
    CFStringRef requestBody = CFSTR("");
    CFDataRef bodyData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, requestBody, kCFStringEncodingUTF8, 0);

    if (_curRequest.HTTPBody) {
        bodyData = (__bridge_retained CFDataRef) _curRequest.HTTPBody;
    }  else if (_curRequest.HTTPBodyStream) {
        NSData *data = [self dataWithInputStream:_curRequest.HTTPBodyStream];
        NSString *strBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        CFDataRef body = (__bridge_retained CFDataRef) data;
        CFHTTPMessageSetBody(cfrequest, body);
        CFRelease(body);
    } else {
        CFHTTPMessageSetBody(cfrequest, bodyData);
    }

    // copy原请求的header信息
    for (NSString* header in headFields) {
        CFStringRef requestHeader = (__bridge CFStringRef) header;
        CFStringRef requestHeaderValue = (__bridge CFStringRef) [headFields valueForKey:header];
        CFHTTPMessageSetHeaderFieldValue(cfrequest, requestHeader, requestHeaderValue);
    }

    // 创建CFHTTPMessage对象的输入流
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, cfrequest);
#pragma clang diagnostic pop
    self.inputStream = (__bridge_transfer NSInputStream *) readStream;

    // 设置SNI host信息，关键步骤
    NSString *host = [_curRequest.allHTTPHeaderFields objectForKey:@"host"];
    if (!host) {
        host = _curRequest.URL.host;
    }

    [_inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
    NSDictionary *sslProperties = [[NSDictionary alloc] initWithObjectsAndKeys: host, (__bridge id) kCFStreamSSLPeerName, nil];
    [_inputStream setProperty:sslProperties forKey:(__bridge_transfer NSString *) kCFStreamPropertySSLSettings];
    [_inputStream setDelegate:self];

    if (!_curRunLoop) {
        // 保存当前线程的runloop，这对于重定向的请求很关键
        self.curRunLoop = [NSRunLoop currentRunLoop];
    }
    // 将请求放入当前runloop的事件队列
    [_inputStream scheduleInRunLoop:_curRunLoop forMode:NSRunLoopCommonModes];
    [_inputStream open];

    CFRelease(cfrequest);
    CFRelease(requestURL);
    cfrequest = NULL;
    CFRelease(bodyData);
    CFRelease(requestBody);
    CFRelease(requestMethod);
}

- (NSData*)dataWithInputStream:(NSInputStream*)stream {
    NSMutableData *data = [NSMutableData data];
    [stream open];
    NSInteger result;
    uint8_t buffer[1024];

    while ((result = [stream read:buffer maxLength:1024]) != 0) {
        if (result > 0) {
            // buffer contains result bytes of data to be handled
            [data appendBytes:buffer length:result];
        } else if (result < 0) {
            // The stream had an error. You can get an NSError object using [iStream streamError]
            data = nil;
            break;
        }
    }
    [stream close];
    return data;
}

#pragma mark - NSStreamDelegate
/**
 * input stream 收到header complete后的回调函数
 */
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (eventCode == NSStreamEventHasBytesAvailable) {
        CFReadStreamRef readStream = (__bridge_retained CFReadStreamRef) aStream;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFHTTPMessageRef message = (CFHTTPMessageRef) CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
#pragma clang diagnostic pop
        if (CFHTTPMessageIsHeaderComplete(message)) {
            // 以防response的header信息不完整
            UInt8 buffer[16 * 1024];
            UInt8 *buf = NULL;
            NSUInteger length = 0;
            NSInputStream *inputstream = (NSInputStream *) aStream;
            NSNumber *alreadyAdded = objc_getAssociatedObject(aStream, (__bridge const void *)(kAnchorAlreadyAdded));
            if (!alreadyAdded || ![alreadyAdded boolValue]) {
                objc_setAssociatedObject(aStream, (__bridge const void *)(kAnchorAlreadyAdded), [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_COPY);
                // 通知client已收到response，只通知一次

                NSDictionary *headDict = (__bridge NSDictionary *) (CFHTTPMessageCopyAllHeaderFields(message));
                CFStringRef httpVersion = CFHTTPMessageCopyVersion(message);
                // 获取响应头部的状态码
                CFIndex statusCode = CFHTTPMessageGetResponseStatusCode(message);
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:_curRequest.URL statusCode:statusCode
                                                                         HTTPVersion:(__bridge NSString *) httpVersion headerFields:headDict];


                [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];

                // 验证证书
                SecTrustRef trust = (__bridge SecTrustRef) [aStream propertyForKey:(__bridge NSString *) kCFStreamPropertySSLPeerTrust];
                SecTrustResultType res = kSecTrustResultInvalid;
                NSMutableArray *policies = [NSMutableArray array];
                NSString *domain = [[_curRequest allHTTPHeaderFields] valueForKey:@"host"];
                if (domain) {
                    [policies addObject:(__bridge_transfer id) SecPolicyCreateSSL(true, (__bridge CFStringRef) domain)];
                } else {
                    [policies addObject:(__bridge_transfer id) SecPolicyCreateBasicX509()];
                }

                // 绑定校验策略到服务端的证书上
                SecTrustSetPolicies(trust, (__bridge CFArrayRef) policies);
                if (SecTrustEvaluate(trust, &res) != errSecSuccess) {
                    [self closeStream:aStream];
                    [self.client URLProtocol:self didFailWithError:[[NSError alloc] initWithDomain:@"can not evaluate the server trust" code:-1 userInfo:nil]];
                    return;
                }
                if (res != kSecTrustResultProceed && res != kSecTrustResultUnspecified) {
                    // 证书验证不通过，关闭input stream
                    [self closeStream:aStream];
                    [self.client URLProtocol:self didFailWithError:[[NSError alloc] initWithDomain:@"fail to evaluate the server trust" code:-1 userInfo:nil]];
                } else {
                    // 证书校验通过
                    if (statusCode >= 300 && statusCode < 400) {
                        // 处理重定向错误码
                        [self closeStream:aStream];
                        [self handleRedirect:message];
                    } else {
                        // 返回成功收到的数据
                        if (![inputstream getBuffer:&buf length:&length]) {
                            NSInteger amount = [inputstream read:buffer maxLength:sizeof(buffer)];
                            buf = buffer;
                            length = amount;
                        }
                        if ((NSInteger)length >= 0) {
                            NSData *data = [[NSData alloc] initWithBytes:buf length:length];
                            [self.client URLProtocol:self didLoadData:data];
                        } else {
                            NSError *error = inputstream.streamError;
                            if (!error) {
                                error = [[NSError alloc] initWithDomain:@"inputstream length is invalid"
                                                                   code:-2
                                                               userInfo:nil];
                            }
                            [aStream removeFromRunLoop:_curRunLoop forMode:NSRunLoopCommonModes];
                            [aStream setDelegate:nil];
                            [aStream close];
                            [self.client URLProtocol:self didFailWithError:error];
                        }
                    }
                }
            } else {
                // 证书已验证过，返回数据
                if (![inputstream getBuffer:&buf length:&length]) {
                    NSInteger amount = [inputstream read:buffer maxLength:sizeof(buffer)];
                    buf = buffer;
                    length = amount;
                }
                if ((NSInteger)length >= 0) {
                    NSData *data = [[NSData alloc] initWithBytes:buf length:length];
                    [self.client URLProtocol:self didLoadData:data];
                } else {
                    NSError *error = inputstream.streamError;
                    if (!error) {
                        error = [[NSError alloc] initWithDomain:@"inputstream length is invalid"
                                                           code:-2
                                                       userInfo:nil];
                    }
                    [aStream removeFromRunLoop:_curRunLoop forMode:NSRunLoopCommonModes];
                    [aStream setDelegate:nil];
                    [aStream close];
                    [self.client URLProtocol:self didFailWithError:error];
                }
            }
            CFRelease((CFReadStreamRef)inputstream);
            CFRelease(message);
        }
    } else if (eventCode == NSStreamEventErrorOccurred) {
        [self closeStream:aStream];
        // 通知client发生错误了
        [self.client URLProtocol:self didFailWithError:
         [[NSError alloc] initWithDomain:@"NSStreamEventErrorOccurred" code:-1 userInfo:nil]];
    } else if (eventCode == NSStreamEventEndEncountered) {
        [self closeStream:_inputStream];
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)closeStream:(NSStream*)stream {
    [stream removeFromRunLoop:_curRunLoop forMode:NSRunLoopCommonModes];
    [stream setDelegate:nil];
    [stream close];
}

- (void)handleRedirect:(CFHTTPMessageRef)messageRef {
    // 响应头
    CFDictionaryRef headerFieldsRef = CFHTTPMessageCopyAllHeaderFields(messageRef);
    NSDictionary *headDict = (__bridge_transfer NSDictionary *)headerFieldsRef;
    [self redirect:headDict];
}

- (void)redirect:(NSDictionary *)headDict {
    // 重定向时如果有cookie需求的话，注意处理
    NSString *location = headDict[@"Location"];
    if (!location)
        location = headDict[@"location"];
    NSURL *url = [[NSURL alloc] initWithString:location];
    _curRequest.URL = url;
    if ([[_curRequest.HTTPMethod lowercaseString] isEqualToString:@"post"]) {
        // 根据RFC文档，当重定向请求为POST请求时，要将其转换为GET请求
        _curRequest.HTTPMethod = @"GET";
        _curRequest.HTTPBody = nil;
    }
    [self startRequest];
}

@end
