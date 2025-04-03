import 'package:dio/dio.dart';

import '../line_detection.dart';

class LineHandleManager {
  /// 启动线路获取处理
  /// 本地缓存为空,则获取全部线路,并返回可用的线路
  /// 如果本地缓存不为空,则初始化Dio,并通过baseUrl去
  static Future<List<String>> startLineCheck({
    required LineDirectionManager manager,
    required String deomain,
    required int platformNum,

    /// 线路测试状态回调
    required Function(LinkInfo)? lineCheckCallBack,

    /// 线路测试完成成功列表状态回调
    required Function(List<LinkInfo>)? lineAvaibleCheckCallBack,

    /// 客服线路测试状态回调
    required Function(LinkInfo)? serverLineCheckCallBack,

    /// 客服企业号
    required Function(String)? serverCode,

    /// 客服线路测试完成成功列表状态回调
    required Function(List<LinkInfo>)? serverLineAvaibleCheckCallBack,

    /// 错误拦截
    void Function({String? url, dynamic error, StackTrace stackTrace})? errorCallback,

    /// 外部传入的测速函数
    required GetLinkDelayTime getLinkDelayTime,
  }) async {
    /// 缓存为空,获取在线可用线路,返回的都是可用的
    List<LinkInfo> onlineLines = await LineFetcherManager.fetchOnlineLinks(
      manager: manager,
      deomain: deomain,
      platformNum: platformNum,
      lineCheckCallBack: lineCheckCallBack,
      lineAvaibleCheckCallBack: lineAvaibleCheckCallBack,
      serverLineCheckCallBack: serverLineCheckCallBack,
      serverLineAvaibleCheckCallBack: serverLineAvaibleCheckCallBack,
      serverCode: serverCode,
      errorCallback: errorCallback,
      getLinkDelayTime: getLinkDelayTime,
    );

    /// 缓存到本地
    // LinkInfoCacheManager cacheManager = LinkInfoCacheManager();
    // cacheManager.saveLinkInfoList(onlineLines);

    /// 转换成地址列表
    List<String> avableLinks = LineFetcherManager.fetchEndpoints(onlineLines);

    return avableLinks;
  }

  /// 判断本地缓存是否存在,如果是直接测试baseUrl
  static Future<List<String>> hasLocalCach() async {
    LinkInfoCacheManager cacheManager = LinkInfoCacheManager();

    /// 获取本地线路缓存
    List<LinkInfo> cacheLines = await cacheManager.getLinkInfoList();
    List<String> avableLineks = LineFetcherManager.fetchEndpoints(cacheLines);
    return avableLineks;
  }

  /// 获取缓存配置
  static Future<LineHttpDnsModelEntity?> getLocalConfig() async {
    return LinkInfoCacheManager().getLineHttpDnsModelEntity();
  }

  /// 对默认线路走Dio测速
  /// 作用:使用APP线路dio,对接口请求,并且过滤异常线路
  static Future<bool> startTestBaseUrl(Dio dio, String url) async {
    try {
      var response = await Future.any([
        dio.get(
          url,
          options: Options(
            sendTimeout: const Duration(seconds: 7),
            receiveTimeout: const Duration(seconds: 7),
          ),
        ),
        Future.delayed(const Duration(seconds: 3), () => null), // 3秒超时
      ]);
      if (response != null && response.data == true) {
        return true;
      } else {
        throw Exception('线路检测结果异常');
      }
    } catch (e) {
      return false;
    }
  }
}
