import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

class LockScreenManager {
  static show({
    required String password,
    required BuildContext context,
    int maxRetries = 3, // 设置最大重试次数
    int errorDelaySeconds = 100, // 错误后延迟时间
    bool errorMaxPop = false, // 多次错误之后回调是否关闭窗口
    required Function onUnlockSuccess, // 成功解锁时的回调
    required Function onErrorExceeded, // 错误次数超过时的回调
  }) {
    final controller = InputController();
    int errorCount = 0; // 错误次数计数器
    int errorCountMax = 0; // 错误分组次数计数器

    screenLock(
      context: context,
      correctString: password,
      inputController: controller,
      maxRetries: maxRetries, // 最大重试次数
      retryDelay: Duration(seconds: errorDelaySeconds), // 错误后的重试延迟
      canCancel: false,
      config: ScreenLockConfig(
        backgroundColor: Colors.black.withValues(alpha: 0.9), // 背景颜色
        titleTextStyle: const TextStyle(fontSize: 24),
      ),

      keyPadConfig: KeyPadConfig(
        buttonConfig: KeyPadButtonConfig(
          buttonStyle: OutlinedButton.styleFrom(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
      title: const Text("请输入锁屏密码", style: TextStyle(fontSize: 16)),
      footer: TextButton(
        onPressed: () {
          // 忘记密码的操作
          print("Forgot password");
        },
        child: const Text("忘记密码"),
      ),
      onOpened: () {
        print("Lock screen opened.");
      },
      onUnlocked: () {
        print("Lock screen unlocked.");
        // 成功解锁后执行回调
        onUnlockSuccess();
        // 确保从 Navigator 弹出
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // 正确的弹出操作
        } else {
          print("No Navigator to pop.");
        }
      },
      onError: (int count) {
        print("Error attempt count: $count");
        errorCount = count;
        // 如果超过最大错误次数，触发错误超出回调
        if (errorCount >= maxRetries) {
          errorCountMax = errorCountMax + 1;
          if (errorCountMax > 2) {
            onErrorExceeded(); // 错误次数过多时的回调

            if (Navigator.canPop(context) && errorMaxPop) {
              Navigator.of(context).pop(); // 正确的弹出操作
            }
          }
          print("Error attempts exceeded maximum retries.");
        }
      },
      delayBuilder: (context, delay) {
        return Text(
          '请等候${(delay.inMilliseconds / 1000).ceil()}S后重试!',
          style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 16),
        );
      },
    );
  }
}
