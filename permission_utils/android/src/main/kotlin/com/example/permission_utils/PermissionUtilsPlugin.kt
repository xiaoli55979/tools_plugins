package com.example.permission_utils

import android.app.Activity
import android.app.AlertDialog
import android.content.DialogInterface
import android.os.Build
import com.hjq.permissions.OnPermissionCallback
import com.hjq.permissions.Permission
import com.hjq.permissions.XXPermissions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** PermissionUtilsPlugin */
class PermissionUtilsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private var mActivity: Activity? = null;

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "permission_utils")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "requestCameraPermission") {
            requestPermission(result, Permission.CAMERA);
        } else if (call.method == "requestAlbumPermission") {
            if (mActivity!!.applicationInfo!!.targetSdkVersion  >= 33) {
                requestPermission(
                    result,
                    Permission.READ_MEDIA_IMAGES,
                    Permission.READ_MEDIA_VIDEO,
                    Permission.READ_MEDIA_AUDIO,
                )
            } else {
                requestPermission(
                    result,
                    Permission.READ_EXTERNAL_STORAGE,
                )
            }
        } else if (call.method == "requestMicrophonePermission") {
            requestPermission(result, Permission.RECORD_AUDIO);
        } else if (call.method == "requestAllPermission") {
            if (mActivity!!.applicationInfo!!.targetSdkVersion >= 33) {
                requestPermission(
                    result,
                    Permission.CAMERA,
                    Permission.READ_MEDIA_IMAGES,
                    Permission.READ_MEDIA_VIDEO,
                    Permission.READ_MEDIA_AUDIO,
                    Permission.RECORD_AUDIO
                )
            } else {
                requestPermission(
                    result,
                    Permission.CAMERA,
                    Permission.READ_EXTERNAL_STORAGE,
                    Permission.RECORD_AUDIO
                )
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        mActivity = null
    }

    private fun requestPermission(result: Result, vararg permissions: String) {
        XXPermissions.with(mActivity!!)
            .permission(permissions)
            .request(object : OnPermissionCallback {
                override fun onGranted(
                    permissions: List<String>,
                    allGranted: Boolean
                ) {
                    if (allGranted) {
                        result.success("true")
                    }
                }

                override fun onDenied(
                    permissions: List<String>,
                    doNotAskAgain: Boolean
                ) {
                    if (doNotAskAgain) {
                        AlertDialog.Builder(mActivity)
                            .setTitle("温馨提示")
                            .setMessage("当前无权限，部分功能将无法使用，请先到设置中心进行授权")
                            .setPositiveButton(
                                "确定"
                            ) { _: DialogInterface?, _: Int ->
                                XXPermissions.startPermissionActivity(
                                    mActivity!!
                                )
                            }.setNegativeButton(
                                "取消"
                            ) { dialog: DialogInterface, _: Int -> dialog.dismiss() }.show()
                    }
                    result.success("false")
                }
            });
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
