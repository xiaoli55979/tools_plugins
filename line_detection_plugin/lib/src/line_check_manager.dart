import 'dart:async';

import 'model/link_info.dart';

/// 函数类型用于测速
typedef GetLinkDelayTime = Future<int> Function({
  required String link,
  int maxTimeOut,
  void Function({String? url, dynamic error, StackTrace stackTrace})? errorCallback,
});

/// 线路状态管理
/// 单条测速或者多条测速
class LineCheckManager {
  /// 对传入的线路进行测速
  /// 回调可用的线路
  static Future<List<LinkInfo>> checkLinkDelays({
    /// 带测速线路
    String? checkLine,

    /// 带测速线路列表
    List<String>? checkLines,

    /// 线路测试状态回调
    Function(LinkInfo)? lineCheckCallBack,

    /// 线路测试完成成功列表状态回调
    Function(List<LinkInfo>)? lineAvaibleCheckCallBack,

    /// 异常信息
    void Function({String? url, dynamic error, StackTrace stackTrace})? errorCallback,

    /// 是否检测到一条正常就结束
    bool abableSkip = false,

    /// 如果abableSkip=true检测到有一条成功就会回调,只针对checkLines
    void Function(bool status)? skipCallBack,

    /// 外部传入的测速函数
    required GetLinkDelayTime getLinkDelayTime,
  }) async {
    /// 检查条件并抛出异常
    if ((checkLine == null || checkLine.isEmpty) && (checkLines == null || checkLines.isEmpty)) {
      final error = Exception("测速异常, checkLine 或者 checkLines 不能同时为空");
      errorCallback?.call(url: checkLine!, error: error, stackTrace: StackTrace.current);
      return [];
    }

    try {
      /// 如果是单条
      if (checkLine != null) {
        int duration = await getLinkDelayTime(link: checkLine, errorCallback: errorCallback);
        LinkInfo linkInfo = LinkInfo(url: checkLine, duration: duration);
        lineCheckCallBack?.call(linkInfo);
        return linkInfo.available ? [linkInfo] : [];
      }

      /// 测速多条
      List<LinkInfo> avalelines = [];

      /// 如果是多条
      final completer = Completer<void>();
      List<Future<void>> futures = checkLines!.map((link) async {
        /// 获取线路速度
        int duration = await getLinkDelayTime(link: link, errorCallback: errorCallback);

        /// 如果已经提前结束则不再执行
        if (completer.isCompleted) return;

        /// 回调单条测速结果
        LinkInfo linkInfo = LinkInfo(url: link, duration: duration);
        lineCheckCallBack?.call(linkInfo);

        /// 添加可用线路到列表
        if (linkInfo.available) {
          avalelines.add(linkInfo);
        }

        /// 如果可以提前跳过
        if (abableSkip) {
          if (!completer.isCompleted) {
            /// 更新测速可用的线路
            completer.complete();
          }
        }
      }).toList();

      // 等待所有 Future 完成或 completer 完成
      await Future.any([Future.wait(futures), completer.future]);

      lineAvaibleCheckCallBack?.call(avalelines);
      return avalelines;
    } catch (error, stackTrace) {
      errorCallback?.call(error: error, stackTrace: stackTrace);
      return [];
    }
  }

  // /// 测试某一条线路的速度
  // static Future<int> getLinkDelayTime({
  //   required String link,
  //   int maxTimeOut = 10,
  //   void Function({String? url, dynamic error, StackTrace stackTrace})? errorCallback,
  // }) async {
  //   String url = "$link/health";
  //   String formatUrl = LineTools.formatUrl(url);
  //
  //   Dio dio = Dio(BaseOptions(
  //     connectTimeout: const Duration(seconds: 10),
  //     sendTimeout: const Duration(seconds: 10),
  //     receiveTimeout: const Duration(seconds: 10),
  //   ));
  //
  //   // 添加异常上报处理
  //   dio.addSentry();
  //
  //   // 启动事务
  //   final transaction = Sentry.startTransaction(
  //     formatUrl,
  //     "线路测速Dio",
  //     bindToScope: true, // 绑定到 Sentry 作用域
  //   );
  //
  //   try {
  //     var startTime = DateTime.now();
  //     var response = await dio.get(formatUrl).timeout(Duration(seconds: maxTimeOut));
  //
  //     var endTime = DateTime.now(); // 记录结束时间
  //
  //     if (response.data == true) {
  //       var duration = endTime.difference(startTime).inMilliseconds; // 计算时长
  //       transaction.status = SpanStatus.fromHttpStatusCode(response.statusCode ?? -1);
  //       return duration;
  //     } else {
  //       transaction.status = const SpanStatus.unknown();
  //       throw Exception('线路测速结果异常');
  //     }
  //   } catch (error, stackTrace) {
  //     transaction.throwable = error;
  //     transaction.status = const SpanStatus.unknown();
  //     if (errorCallback != null) {
  //       errorCallback(url: formatUrl, error: error, stackTrace: stackTrace);
  //     }
  //     return 20000; // 超时或者异常时返回默认值
  //   } finally {
  //     // 结束事务
  //     await transaction.finish();
  //   }
  // }
}
