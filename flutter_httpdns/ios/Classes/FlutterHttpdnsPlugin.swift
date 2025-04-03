import Flutter
import UIKit

public class FlutterHttpdnsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {


    var methodChannel: FlutterMethodChannel?
    var eventChannel: FlutterEventChannel?
    var eventSink: FlutterEventSink?

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        // 清理资源或停止操作
        methodChannel?.setMethodCallHandler(nil)
        eventChannel?.setStreamHandler(nil)
    }


    
    /// 初始化管理单例
    private var _manager: HttpDnsManager?
        var manager: HttpDnsManager {
            if _manager == nil {
                _manager = HttpDnsManager.sharedInstance()
            }
            return _manager!
        }
    


    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterHttpdnsPlugin()

        // 初始化 methodChannel 和 eventChannel
        instance.methodChannel = FlutterMethodChannel(name: "flutter_httpdns", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        instance.eventChannel = FlutterEventChannel(name: "flutter_httpdns_event", binaryMessenger: registrar.messenger())
        instance.eventChannel?.setStreamHandler(instance)
    }


    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            do {
                switch call.method {
                case "init":
                    // 处理 init 方法
                    if let arguments = call.arguments {
                        manager.initHttpsDns(arguments, result: result)
                    } else {
                        throw NSError(domain: "InvalidArguments", code: 100, userInfo: [NSLocalizedDescriptionKey: "Arguments for init method are missing"])
                    }

                case "getAddrByNameAsync":
                    // 处理 getAddrByNameAsync 方法
                    if let arguments = call.arguments {
                        manager.getAddrByNameAsync(arguments, result: result)
                    } else {
                        throw NSError(domain: "InvalidArguments", code: 101, userInfo: [NSLocalizedDescriptionKey: "Arguments for getAddrByNameAsync method are missing"])
                    }

                case "getAddrsByNameAsync":
                    // 处理 getAddrsByNameAsync 方法
                    if let arguments = call.arguments {
                        manager.getAddrsByNameAsync(arguments, result: result)
                    } else {
                        throw NSError(domain: "InvalidArguments", code: 102, userInfo: [NSLocalizedDescriptionKey: "Arguments for getAddrsByNameAsync method are missing"])
                    }

                case "getConfig":
                    // 处理 getConfig 方法
                    if let arguments = call.arguments {
                       
                        manager.getConfig(arguments) { response, error , url in
                            if error != nil {
                                if let eventSink = self.eventSink {
                                    DispatchQueue.main.async {
                                        var obj: [String: Any] = [:]
                                        obj["url"] = url
                                        obj["error"] = error?.localizedDescription
                                        eventSink(obj)
                                    }
                                }
                            } else {
                                if let response = response as? [String: Any], !response.isEmpty {
                                    result(response)
                                } else {
                                    result(FlutterError(code: "exception", message: "线路获取异常", details: nil))
                                }
                            }
                        }

                        
                    } else {
                        throw NSError(domain: "InvalidArguments", code: 103, userInfo: [NSLocalizedDescriptionKey: "Arguments for getConfig method are missing"])
                    }

                case "cleanCache":
                    manager.clearAllCache();
                    result("success");
                    break;
                    
                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch {
                // 捕获异常并返回 FlutterError
                result(FlutterError(code: "ERROR_CODE", message: error.localizedDescription, details: nil))
            }
        }
}
