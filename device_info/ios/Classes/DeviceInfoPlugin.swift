import Flutter
import UIKit
import KeychainAccess
import AdSupport

public class DeviceInfoPlugin: NSObject, FlutterPlugin {

  static let KEYCHAIN_SERVICE:String = "com.abg.device_info"
  static let KEYCHAIN_GROUP:String = "ASSCER_GROUP"
  static let IMEI_KEY:String = "IMEI"
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.abg.device_info", binaryMessenger: registrar.messenger())
    let instance = DeviceInfoPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if (call.method == "getInfo") {
        var sysInfo = utsname()
        uname(&sysInfo)
        let current = UIDevice.current
        result([
          // DeviceInfo
          "deviceId": getUUID(),
          "platform": current.systemName, // e.g.. iOS
          "platformVersion": current.systemVersion, // e.g.. 14.2
          "architecture": cpuType(), // e.g.. armv7
          "model": current.model, // e.g.. iPhone, iPod touch
          "brand": Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? "App", // e.g.. Sample App
          "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"), // e.g.. 1.0.0
          "mobile": current.userInterfaceIdiom == .phone || current.userInterfaceIdiom == .pad, // true/false
  				"device": device(), // e.g.. iPhone13,4

          // PackageData
          "appName": Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName"), // e.g.. Sample App
          "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"), // e.g.. 1.0.0
          "packageName": Bundle.main.bundleIdentifier, // e.g.. jp.wasabeef.ua
          "buildNumber": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion"), // e.g.. 1
          "isPhysicalDevice": isDevicePhysical(),
          "isRoot":isJailbroken(),
        ])
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    func device() -> String {
      var sysInfo = utsname()
      uname(&sysInfo)
      let machine = String(bytes: Data(bytes: &sysInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)

      return machine == "x86_64" || machine == "i386" ? "Simulator" : machine
    }
    
    /// getUUID
    func getUUID() -> String{
        var uuid:String? = getAdvertisingId()
        if uuid == nil {
            uuid = ""
            let keychain = Keychain(service: DeviceInfoPlugin.KEYCHAIN_SERVICE)
            do {
                uuid = try keychain.get(DeviceInfoPlugin.IMEI_KEY) ?? ""
            }
            catch let error {
                print(error)
            }
            if uuid!.isEmpty {
                uuid = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                do {
                    try keychain.set(uuid!, key: DeviceInfoPlugin.IMEI_KEY)
                }
                catch let error {
                    print(error)
                    uuid = ""
                }
            }
        }
//        print("uuid:\(uuid)")
        return uuid!
    }
    
    func getAdvertisingId() -> String? {
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
//            print("Vendor ID: \(vendorId)")
        }
        
        // 检查是否允许追踪广告
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            // 获取广告标识符
            let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
//            print("advertisingId:\(advertisingId)")
            return advertisingId
        } else {
//            print("用户禁用了广告跟踪")
            return nil
        }
    }
    
    
    func getAdvertisingID() {
        let advertisingID = ASIdentifierManager.shared().advertisingIdentifier
        let advertisingIDString = advertisingID.uuidString
//        print("Advertising ID: \(advertisingIDString)")
    }
    
    func isDevicePhysical() -> String {
        #if targetEnvironment(simulator)
            let isPhysicalDevice = "false"
        #else
            let isPhysicalDevice = "true"
        #endif
        
        return isPhysicalDevice
    }
    
    // 检测越狱状态
    func isJailbroken() -> Bool {
        let fileManager = FileManager.default
        
        // 检查常见越狱工具的路径
        let commonPaths = ["/Applications/Cydia.app", "/Library/MobileSubstrate/MobileSubstrate.dylib", "/bin/bash"]
        for path in commonPaths {
            if fileManager.fileExists(atPath: path) {
                print("commonPaths_1");
                return true
            }
        }
        
        // 检查越狱系统文件夹
        let jailbreakDirs = ["/Library/MobileSubstrate", "/usr/libexec/cydia"]
        for dir in jailbreakDirs {
            if fileManager.fileExists(atPath: dir) {
                print("commonPaths_2_:\(dir)");
                return true
            }
        }
        
        // 检查是否能够读取系统文件
        do {
            let hostsContents = try String(contentsOfFile: "/etc/hosts")
            if hostsContents.contains("gs.apple.com") {
                print("commonPaths_3");
                return true
            }
        } catch {
            // 处理读取文件失败的情况
        }
        
        // 检查是否有权限读取系统文件夹
        if fileManager.fileExists(atPath: "/private/var/lib/apt/") {
            print("commonPaths_4");
            return true
        }
        
//        // 检查是否能够执行某些命令
//        if let cydiaUrl = URL(string: "cydia://package/com.example.package") {
//            if UIApplication.shared.canOpenURL(cydiaUrl) {
//                print("commonPaths_5");
//                return true
//            }
//        }
        return false
    }
    
    func cpuType() -> String {
      var type = cpu_type_t()
      var cpuSize = MemoryLayout<cpu_type_t>.size
      sysctlbyname("hw.cputype", &type, &cpuSize, nil, 0)

      var subType = cpu_subtype_t()
      var subTypeSize = MemoryLayout<cpu_subtype_t>.size
      sysctlbyname("hw.cpusubtype", &subType, &subTypeSize, nil, 0)

      switch type {
      case CPU_TYPE_X86_64:
        switch subType {
        case CPU_SUBTYPE_X86_64_H: return "x86_64h"
        case CPU_SUBTYPE_X86_ARCH1: return "x86_arch1"
        case CPU_SUBTYPE_X86_64_ALL: return "x86_64"
        default: return "x86_64"
        }
      case CPU_TYPE_X86: return "x86"

      case CPU_TYPE_ARM:
        switch subType {
        case CPU_SUBTYPE_ARM_V8: return "armv8"
        case CPU_SUBTYPE_ARM_V7: return "armv7"
        case CPU_SUBTYPE_ARM_V7EM: return "armv7em"
        case CPU_SUBTYPE_ARM_V7F: return "armv7f"
        case CPU_SUBTYPE_ARM_V7K: return "armv7k"
        case CPU_SUBTYPE_ARM_V7M: return "armv7m"
        case CPU_SUBTYPE_ARM_V7S: return "armv7s"
        case CPU_SUBTYPE_ARM_V6: return "armv6"
        case CPU_SUBTYPE_ARM_V6M: return "armv6m"
        case CPU_SUBTYPE_ARM_V4T: return "armv4t"
        case CPU_SUBTYPE_ARM_V5TEJ: return "armv5"
        case CPU_SUBTYPE_ARM_XSCALE: return "xscale"
        case CPU_SUBTYPE_ARM_ALL: return "arm"
        default: return "arm"
        }

      case CPU_TYPE_ARM64:
        switch subType {
        case CPU_SUBTYPE_ARM64_V8: return "arm64v8"
        case CPU_SUBTYPE_ARM64E: return "arm64e"
        case CPU_SUBTYPE_ARM64_ALL: return "arm64"
        default: return "arm64"
        }

      case CPU_TYPE_ARM64_32: return "arm64_32"

      case CPU_TYPE_POWERPC: return "ppc"
      case CPU_TYPE_POWERPC64: return "ppc64"
      case CPU_TYPE_VAX: return "vax"
      case CPU_TYPE_I860: return "i860"
      case CPU_TYPE_I386: return "i386"
      case CPU_TYPE_HPPA: return "hppa"
      case CPU_TYPE_SPARC: return "sparc"
      case CPU_TYPE_MC88000: return "m88k"

      case CPU_TYPE_ANY: return "any"
      default: return "unknown"
      }
    }
}
