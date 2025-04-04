#include "include/permission_utils/permission_utils_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "permission_utils_plugin.h"

void PermissionUtilsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  permission_utils::PermissionUtilsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
