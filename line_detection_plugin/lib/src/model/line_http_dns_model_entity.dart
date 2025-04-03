import 'dart:convert';

import 'package:line_detection_plugin/generated/json/base/json_field.dart';
import 'package:line_detection_plugin/generated/json/line_http_dns_model_entity.g.dart';

export 'package:line_detection_plugin/generated/json/line_http_dns_model_entity.g.dart';

@JsonSerializable()
class LineHttpDnsModelEntity {
  late int dnsId = 0;
  late String dnsToken = '';
  late List<String> endpoints = [];
  late List<String> domains = [];
  late List<String> oss = [];
  late List<String> reports = [];

  /// 客服企业code
  late String goflyCode = '';

  /// 客服线路
  late String goflyApi = '';

  /// 客服线路备用
  late String goflyApiBackup = '';

  /// 神策api线路
  late String sensorsApi = '';

  /// FeatureProbe api地址
  late String featureprobeApi = '';

  LineHttpDnsModelEntity();

  factory LineHttpDnsModelEntity.fromJson(Map<String, dynamic> json) => $LineHttpDnsModelEntityFromJson(json);

  Map<String, dynamic> toJson() => $LineHttpDnsModelEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
