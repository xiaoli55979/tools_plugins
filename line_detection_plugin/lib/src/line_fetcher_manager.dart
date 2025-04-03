import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter_httpdns/flutter_httpdns.dart';

import '../line_detection.dart';

/// 线路获取
/// 最新线路获取
/// 缓存线路获取
/// 线路更新
class LineFetcherManager {
  /// 获取缓存线路列表
  static Future<List<LinkInfo>> fetchCachedLinks() async {
    try {
      final cacheManager = LinkInfoCacheManager();
      final List<LinkInfo> cachedLinks = await cacheManager.getLinkInfoList();
      return cachedLinks;
    } catch (e) {
      return [];
    }
  }

  /// 获取在线线路
  // manager:线路获取管理插件
  // errorCallback:异常回调
  // deomain:默认配置域名
  // getPlatformNum:平台编码 如:808:1  988:2
  static Future<List<LinkInfo>> fetchOnlineLinks({
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

    /// 异常信息
    void Function({String? url, dynamic error, StackTrace stackTrace})? errorCallback,

    /// 外部传入的测速函数
    required GetLinkDelayTime getLinkDelayTime,
  }) async {
    try {
      FlutterHttpdns? httpDnsManager = LineDirectionManager.instance.httpLinesPlugs;
      if (httpDnsManager == null) {
        errorCallback?.call(error: Exception("线路获取插件未初始化"), stackTrace: StackTrace.current);
        return [];
      }

      /// 获取线路
      deomain = LineTools.extractHost(deomain);
      var result = await httpDnsManager.getConfig(deomain, platformNum, "default");

      /// 缓存初始配置在本地
      final map = Map<String, dynamic>.from(result as Map);
      debugPrint("取到httpDns接口线路:${map.toString()}");
      LineHttpDnsModelEntity entity = LineHttpDnsModelEntity.fromJson(map);
      await LinkInfoCacheManager().saveLineHttpDnsModelEntity(entity);

      /// 客服企业号
      serverCode?.call(entity.goflyCode);

      /// 测速客服线路
      final List<String> serverLins = [
        if (entity.goflyApi.isNotEmpty) entity.goflyApi,
        if (entity.goflyApiBackup.isNotEmpty) entity.goflyApiBackup,
      ];
      await LineCheckManager.checkLinkDelays(
        checkLines: serverLins,
        lineCheckCallBack: (LinkInfo link) {
          if (link.url.contains(entity.goflyApi)) {
            link.main = true;
          }
          serverLineCheckCallBack?.call(link);
        },
        lineAvaibleCheckCallBack: (List<LinkInfo> linkList) {
          serverLineAvaibleCheckCallBack?.call(linkList);
        },
        errorCallback: errorCallback,
        getLinkDelayTime: getLinkDelayTime,
      );

      /// 对线路进行全量测速,只保留可用的
      List<LinkInfo> avableLines = await LineCheckManager.checkLinkDelays(
        checkLines: entity.endpoints,
        lineCheckCallBack: (LinkInfo link) {
          lineCheckCallBack?.call(link);
        },
        lineAvaibleCheckCallBack: lineAvaibleCheckCallBack,
        errorCallback: errorCallback,
        getLinkDelayTime: getLinkDelayTime,
      );

      /// 保存更新后的到本地
      LinkInfoCacheManager cacheManager = LinkInfoCacheManager();
      cacheManager.saveLinkInfoList(avableLines);
      return avableLines;
    } catch (error, stackTrace) {
      errorCallback?.call(error: error, stackTrace: stackTrace);
      return [];
    }
  }

  /// 转换线路列表,由LinkInfo--> String
  /// 自动带上http开头
  static List<String> fetchEndpoints(List<LinkInfo> lineks) {
    List<String> list = [];
    for (LinkInfo link in lineks) {
      String formatUrl = LineTools.formatUrl(link.url);
      list.add(formatUrl);
    }
    return list;
  }
}
