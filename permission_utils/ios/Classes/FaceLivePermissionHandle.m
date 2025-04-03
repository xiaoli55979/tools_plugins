
#import "FaceLivePermissionHandle.h"
#import <UIKit/UIKit.h>
@import AVFoundation;
@import Photos;

#define kMsgTitle @"访问权限已被拒绝,请到系统设置中打开"

@implementation FaceLivePermissionHandle

/// 请求相机相册麦克风权限
+ (void)requestPermissions:(PermissionCallback)callback {
    [self checkPhotoLibraryPermissionWithCallback:^(BOOL granted, NSString * _Nonnull message) {
        if (granted) {
            [self checkCameraPermissionWithCallback:^(BOOL grantedcam, NSString * _Nonnull message) {
                callback(grantedcam,message);
            }];
        } else {
            callback(NO,@"相册权限已被拒绝");
            [self showPermissionDeniedAlertWithTitle:@"提示" message:[@"相册" stringByAppendingString:kMsgTitle] confirm:@"确定" cancel:@"取消" callback:^(BOOL status) {
                if (status) {
                    [self openAppSettings];
                }
            }];
        }
    }];
}

+ (void)checkCameraPermissionWithCallback:(PermissionCallback)callback {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized: {
            callback(YES,@"相机权限已授权");
        }
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    callback(YES,@"相机权限已授权");
                } else {
                    callback(NO,@"相机权限被拒绝");
                    [self showPermissionDeniedAlertWithTitle:@"提示" message:[@"相机" stringByAppendingString:kMsgTitle] confirm:@"确定" cancel:@"取消" callback:^(BOOL status) {
                        if (status) {
                            [self openAppSettings];
                        }
                    }];
                }
            }];
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted: {
            [self showPermissionDeniedAlertWithTitle:@"提示" message:[@"相机" stringByAppendingString:kMsgTitle] confirm:@"确定" cancel:@"取消" callback:^(BOOL status) {
                if (status) {
                    [self openAppSettings];
                }
            }];
            break;
        }
        default:
            break;
    }
}

+ (void)checkPhotoLibraryPermissionWithCallback:(PermissionCallback)callback {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusAuthorized: {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(YES,@"相册权限已授权");
                });
            break;
        }
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(YES,@"相册权限已授权");
                        });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(NO,@"相册权限被拒绝");
                        [self showPermissionDeniedAlertWithTitle:@"提示" message:[@"相册" stringByAppendingString:kMsgTitle] confirm:@"确定" cancel:@"取消" callback:^(BOOL status) {
                            if (status) {
                                [self openAppSettings];
                            }
                        }];
                        });
                }
//                callback(status == PHAuthorizationStatusAuthorized);
            }];
            break;
        }
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted: {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(NO,@"相册权限被拒绝或受限");
                [self showPermissionDeniedAlertWithTitle:@"提示" message:[@"相册" stringByAppendingString:kMsgTitle] confirm:@"确定" cancel:@"取消" callback:^(BOOL status) {
                    if (status) {
                        [self openAppSettings];
                    }
                }];
                });
            break;
        }
        default:
            break;
    }
}

+ (void)checkMicrophonePermissionWithCallback:(PermissionCallback)callback {
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    switch (permission) {
        case AVAudioSessionRecordPermissionGranted: {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(YES,@"麦克风权限已授权");
                });
            break;
        }
        case AVAudioSessionRecordPermissionUndetermined: {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(YES,@"麦克风权限已授权");
                        });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(NO,@"麦克风权限被拒绝");
                        [self showPermissionDeniedAlertWithTitle:@"提示" message:[@"麦克风" stringByAppendingString:kMsgTitle] confirm:@"确定" cancel:@"取消" callback:^(BOOL status) {
                            if (status) {
                                [self openAppSettings];
                            }
                        }];
                        });
                }
            }];
            break;
        }
        case AVAudioSessionRecordPermissionDenied: {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(NO,@"麦克风权限被拒绝");
                [self showPermissionDeniedAlertWithTitle:@"提示" message:[@"麦克风" stringByAppendingString:kMsgTitle] confirm:@"确定" cancel:@"取消" callback:^(BOOL status) {
                    if (status) {
                        [self openAppSettings];
                    }
                }];
                });
            break;
        }
        default:
            break;
    }
}


+ (void)showPermissionDeniedAlertWithTitle:(NSString *)title
                                   message:(NSString *)message
                                   confirm:(NSString *)confirmTitle
                                    cancel:(NSString *)cancelTitle
                                   callback:(void (^)(BOOL))callback {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        callback(NO);
    }];

    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        callback(YES);
    }];

    [alertController addAction:cancelAction];
    [alertController addAction:settingsAction];

    [[self getCurrentViewController] presentViewController:alertController animated:YES completion:nil];
}


+ (UIViewController *)getCurrentViewController {
    // 获取当前应用的根视图控制器
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    keyWindow = windowScene.windows.firstObject;
                    break;
                }
            }
        } else {
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
    UIViewController *rootViewController = keyWindow.rootViewController;
    
    // 如果是导航控制器，则获取顶层的视图控制器
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return navigationController.topViewController;
    }

    // 如果是标签栏控制器，则获取选中的视图控制器
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewController;
        return tabBarController.selectedViewController;
    }

    // 其他情况直接返回根视图控制器
    return rootViewController;
}


+ (void)openAppSettings {
    NSURL *appSettingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:appSettingsURL]) {
        [[UIApplication sharedApplication] openURL:appSettingsURL options:@{} completionHandler:nil];
    }
}

@end


