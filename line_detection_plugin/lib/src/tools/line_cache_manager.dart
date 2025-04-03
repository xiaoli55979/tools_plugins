import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/line_http_dns_model_entity.dart';
import '../model/link_info.dart';

/// 缓存线路管理
class LinkInfoCacheManager {
  // 私有构造函数
  LinkInfoCacheManager._privateConstructor();

  // 单例实例
  static final LinkInfoCacheManager _instance = LinkInfoCacheManager._privateConstructor();

  // 工厂构造函数，返回单例实例
  factory LinkInfoCacheManager() {
    return _instance;
  }

  // 线路列表
  static const _cacheKeyLinkInfo = 'link_info_cache';
  // 基础使用线路列表
  static const _cacheKeyBaseUrl = 'base_url_cache';
  // LineHttpDnsModelEntity 缓存键
  static const _cacheKeyLineHttpDnsModelEntity = 'line_http_dns_model_entity_cache';

  // 保存 LinkInfo 列表到缓存 -- 通过List<String>过滤本都多余的线路
  Future<void> saveLinkInfoListFromLocal(List<String> linkStringList) async {
    final prefs = await SharedPreferences.getInstance();
    List<LinkInfo> linkInfoList = [];
    List<LinkInfo> orangeLinks = await getLinkInfoList();
    for (String line in linkStringList) {
      for (LinkInfo linkInfo in orangeLinks) {
        if (line == linkInfo.url) {
          linkInfoList.add(linkInfo);
        }
      }
    }
    final List<Map<String, dynamic>> jsonList = linkInfoList.map((info) => info.toMap()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_cacheKeyLinkInfo, jsonString);
  }

  // 保存 LinkInfo 列表到缓存
  Future<void> saveLinkInfoList(List<LinkInfo> linkInfoList) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = linkInfoList.map((info) => info.toMap()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_cacheKeyLinkInfo, jsonString);
  }

  // 获取 LinkInfo 从缓存获取列表
  Future<List<LinkInfo>> getLinkInfoList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKeyLinkInfo);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => LinkInfo.fromMap(Map<String, dynamic>.from(json))).toList();
  }

  // 更新或替换 LinkInfo
  Future<void> updateLinkInfo(LinkInfo newLinkInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKeyLinkInfo);
    if (jsonString == null) {
      await saveLinkInfoList([newLinkInfo]);
      return;
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final List<LinkInfo> linkInfoList = jsonList.map((json) => LinkInfo.fromMap(Map<String, dynamic>.from(json))).toList();

    // 替换旧的 LinkInfo 或添加新的
    final updatedList = linkInfoList.where((info) => info.url != newLinkInfo.url).toList();
    updatedList.add(newLinkInfo);

    await saveLinkInfoList(updatedList);
  }

  // 保存 baseUrl 到缓存
  Future<void> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKeyBaseUrl, baseUrl);
  }

  // 获取 baseUrl 从缓存
  Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKeyBaseUrl);
  }

  // 保存 LineHttpDnsModelEntity 对象到缓存
  Future<void> saveLineHttpDnsModelEntity(LineHttpDnsModelEntity entity) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(entity);
    await prefs.setString(_cacheKeyLineHttpDnsModelEntity, jsonString);
  }

  // 获取 LineHttpDnsModelEntity 对象从缓存
  Future<LineHttpDnsModelEntity?> getLineHttpDnsModelEntity() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_cacheKeyLineHttpDnsModelEntity);
    if (jsonString != null) {
      return LineHttpDnsModelEntity.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  /// 获取缓存中的 dnsId，如果不存在则返回默认值
  Future<String> getCacheDnsId(String defaultDnsId) async {
    LineHttpDnsModelEntity? entity = await getLineHttpDnsModelEntity();
    if (entity != null && entity.dnsId > 0) {
      return "${entity.dnsId}";
    }
    return defaultDnsId;
  }

  /// 从缓存获取dnsid
  Future<String> getCacheDnsToken(String defaultDnsToken) async {
    LineHttpDnsModelEntity? entity = await getLineHttpDnsModelEntity();
    if (entity != null && entity.dnsToken.isNotEmpty) {
      return "${entity.dnsToken}";
    }
    return defaultDnsToken;
  }

  /// 从缓存获取Reports
  Future<List<String>> getCacheReports(List<String> reports) async {
    LineHttpDnsModelEntity? entity = await getLineHttpDnsModelEntity();
    if (entity != null) {
      return entity.reports;
    }
    return reports;
  }

  // 清除缓存
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyLinkInfo);
    await prefs.remove(_cacheKeyBaseUrl);
    await prefs.remove(_cacheKeyLineHttpDnsModelEntity);
  }
}
