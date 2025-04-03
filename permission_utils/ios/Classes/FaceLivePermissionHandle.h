//
//  FaceLivePermissionHandle.h
//  FaceLivePlugin
//
//  Created by 阿浩 on 20/1/2024.
//  Copyright © 2024 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^PermissionCallback)(BOOL granted,NSString *message);

@interface FaceLivePermissionHandle : NSObject
/// 请求相机相册麦克风权限
+ (void)requestPermissions:(PermissionCallback)callback;

// 获取相机权限
+ (void)checkCameraPermissionWithCallback:(PermissionCallback)callback;

// 获取相册权限
+ (void)checkPhotoLibraryPermissionWithCallback:(PermissionCallback)callback;

// 获取麦克风权限
+ (void)checkMicrophonePermissionWithCallback:(PermissionCallback)callback;

@end

NS_ASSUME_NONNULL_END

