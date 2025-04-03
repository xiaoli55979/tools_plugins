import Flutter
import UIKit


public class PermissionUtilsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "permission_utils", binaryMessenger: registrar.messenger())
    let instance = PermissionUtilsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestCameraPermission":
        print("requestCameraPermission");
        FaceLivePermissionHandle.checkCameraPermission { status, msg in
            print("Status:\(status) msg:\(msg)")
            if status {
                result("true")
            } else {
                result("false")
            }
        }
        break;
    case "requestAlbumPermission":
        print("requestAlbumPermission");
        FaceLivePermissionHandle.checkPhotoLibraryPermission { status, msg in
            print("Status:\(status) msg:\(msg)")
            if status {
                result("true")
            } else {
                result("false")
            }
        }
        break;
    case "requestMicrophonePermission":
        print("requestMicrophonePermission");
        FaceLivePermissionHandle.checkMicrophonePermission { status, msg in
            print("Status:\(status) msg:\(msg)")
            if status {
                result("true")
            } else {
                result("false")
            }
        }
        break;
    case "requestAllPermission":
        print("requestAllPermission");
        FaceLivePermissionHandle.requestPermissions { status, msg in
            print("Status:\(status) msg:\(msg)")
            if status {
                result("true")
            } else {
                result("false")
            }
        }
        break;
    default:
        result("false")
    }
  }
}
