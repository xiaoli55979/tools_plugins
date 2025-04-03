package com.abg.device_info

import android.annotation.SuppressLint
import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.File
import java.io.FileReader


/** DeviceInfoPlugin */
class DeviceInfoPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.abg.device_info")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getInfo") {
            val info: PackageInfo? = try {
                val packageManager = context.packageManager
                packageManager.getPackageInfo(context.packageName, PackageManager.GET_META_DATA)
            } catch (e: PackageManager.NameNotFoundException) {
                null
            }

            val uiManager = context.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager

            result.success(
                mapOf(
                    // UserAgentData
                    "deviceId" to getAndroidId(),
                    "platform" to "Android",
                    "platformVersion" to Build.VERSION.RELEASE, // e.g.. 10
                    "architecture" to Build.SUPPORTED_ABIS[0], // e.g.. armv7
                    "model" to Build.MODEL, // e.g.. Pixel 4 XL
                    "brand" to info?.applicationInfo?.loadLabel(context.packageManager)
                        ?.toString(), // e.g.. Sample App
                    "version" to info?.versionName, // e.g.. 1.0.0
                    "mobile" to (uiManager.currentModeType == Configuration.UI_MODE_TYPE_NORMAL), // true/false
                    "device" to Build.DEVICE, // e.g.. coral

                    // PackageData
                    "appName" to info?.applicationInfo?.loadLabel(context.packageManager)
                        ?.toString(), // e.g.. Sample App
                    "appVersion" to info?.versionName, // e.g.. 1.0.0
                    "packageName" to info?.applicationInfo?.packageName, // e.g..  jp.wasabeef.ua
                    "buildNumber" to getVersionCode(context), // e.g.. 1,
                    "isPhysicalDevice" to !isEmulator,
                    "isRoot" to isDeviceRooted(),
                    "isPhone" to isTablet(context),
                )
            )
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    @Suppress("DEPRECATION")
    private fun getVersionCode(context: Context): String {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        return if (Build.VERSION.SDK_INT >= 28) packageInfo.longVersionCode.toString() else packageInfo.versionCode.toString()
    }

    @SuppressLint("HardwareIds")
    private fun getAndroidId(): String {
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
    }

    /**
     * A simple emulator-detection based on the flutter tools detection logic and a couple of legacy
     * detection systems
     */
    private val isEmulator: Boolean
        get() = ((Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
                || Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("vbox86p")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator"))

//    fun isTablet(): Boolean {
//        try {
//            val displayMetricsFile = FileReader("/sys/class/graphics/fb0/virtual_size")
//            val br = BufferedReader(displayMetricsFile)
//            val displayMetricsContent = br.readLine()
//            br.close()
//
//            val dimensions = displayMetricsContent.split(",")
//            val screenWidth = dimensions[0].toInt()
//            val screenHeight = dimensions[1].toInt()
//
//            // 假设大于等于7英寸的设备被认为是平板电脑
//            val diagonalSize = Math.sqrt(Math.pow(screenWidth.toDouble(), 2.0) + Math.pow(screenHeight.toDouble(), 2.0))
//            return diagonalSize >= 7
//        } catch (e: Exception) {
//            e.printStackTrace()
//        }
//        return false
//    }

    private fun isTablet(context: Context): Boolean {
        return (context.resources.configuration.screenLayout and Configuration.SCREENLAYOUT_SIZE_MASK) >= Configuration.SCREENLAYOUT_SIZE_LARGE
    }

    private fun isDeviceRooted(): Boolean {
        val paths = arrayOf(
            "/sbin/su", "/system/bin/su", "/system/xbin/su", "/data/local/xbin/su",
            "/data/local/bin/su", "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su"
        )
        for (path in paths) {
            if (File(path).exists()) {
                return true
            }
        }
        return false
    }

}
