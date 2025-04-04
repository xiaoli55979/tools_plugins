#ifndef FLUTTER_PLUGIN_PERMISSION_UTILS_PLUGIN_H_
#define FLUTTER_PLUGIN_PERMISSION_UTILS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace permission_utils {

class PermissionUtilsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PermissionUtilsPlugin();

  virtual ~PermissionUtilsPlugin();

  // Disallow copy and assign.
  PermissionUtilsPlugin(const PermissionUtilsPlugin&) = delete;
  PermissionUtilsPlugin& operator=(const PermissionUtilsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace permission_utils

#endif  // FLUTTER_PLUGIN_PERMISSION_UTILS_PLUGIN_H_
