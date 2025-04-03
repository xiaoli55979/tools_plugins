import 'package:line_detection_plugin/generated/json/base/json_convert_content.dart';
import 'package:line_detection_plugin/src/model/line_http_dns_model_entity.dart';

LineHttpDnsModelEntity $LineHttpDnsModelEntityFromJson(Map<String, dynamic> json) {
  final LineHttpDnsModelEntity lineHttpDnsModelEntity = LineHttpDnsModelEntity();
  final int? dnsId = jsonConvert.convert<int>(json['dnsId']);
  if (dnsId != null) {
    lineHttpDnsModelEntity.dnsId = dnsId;
  }
  final String? dnsToken = jsonConvert.convert<String>(json['dnsToken']);
  if (dnsToken != null) {
    lineHttpDnsModelEntity.dnsToken = dnsToken;
  }
  final List<String>? endpoints = (json['endpoints'] as List<dynamic>?)?.map((e) => jsonConvert.convert<String>(e) as String).toList();
  if (endpoints != null) {
    lineHttpDnsModelEntity.endpoints = endpoints;
  }
  final List<String>? domains = (json['domains'] as List<dynamic>?)?.map((e) => jsonConvert.convert<String>(e) as String).toList();
  if (domains != null) {
    lineHttpDnsModelEntity.domains = domains;
  }
  final List<String>? oss = (json['oss'] as List<dynamic>?)?.map((e) => jsonConvert.convert<String>(e) as String).toList();
  if (oss != null) {
    lineHttpDnsModelEntity.oss = oss;
  }
  final List<String>? reports = (json['reports'] as List<dynamic>?)?.map((e) => jsonConvert.convert<String>(e) as String).toList();
  if (reports != null) {
    lineHttpDnsModelEntity.reports = reports;
  }
  final String? goflyCode = jsonConvert.convert<String>(json['goflyCode']);
  if (goflyCode != null) {
    lineHttpDnsModelEntity.goflyCode = goflyCode;
  }
  final String? goflyApi = jsonConvert.convert<String>(json['goflyApi']);
  if (goflyApi != null) {
    lineHttpDnsModelEntity.goflyApi = goflyApi;
  }
  final String? goflyApiBackup = jsonConvert.convert<String>(json['goflyApiBackup']);
  if (goflyApiBackup != null) {
    lineHttpDnsModelEntity.goflyApiBackup = goflyApiBackup;
  }
  final String? sensorsApi = jsonConvert.convert<String>(json['sensorsApi']);
  if (sensorsApi != null) {
    lineHttpDnsModelEntity.sensorsApi = sensorsApi;
  }
  final String? featureprobeApi = jsonConvert.convert<String>(json['featureprobeApi']);
  if (featureprobeApi != null) {
    lineHttpDnsModelEntity.featureprobeApi = featureprobeApi;
  }
  return lineHttpDnsModelEntity;
}

Map<String, dynamic> $LineHttpDnsModelEntityToJson(LineHttpDnsModelEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['dnsId'] = entity.dnsId;
  data['dnsToken'] = entity.dnsToken;
  data['endpoints'] = entity.endpoints;
  data['domains'] = entity.domains;
  data['oss'] = entity.oss;
  data['reports'] = entity.reports;
  data['goflyCode'] = entity.goflyCode;
  data['goflyApi'] = entity.goflyApi;
  data['goflyApiBackup'] = entity.goflyApiBackup;
  data['sensorsApi'] = entity.sensorsApi;
  data['featureprobeApi'] = entity.featureprobeApi;
  return data;
}

extension LineHttpDnsModelEntityExtension on LineHttpDnsModelEntity {
  LineHttpDnsModelEntity copyWith({
    int? dnsId,
    String? dnsToken,
    List<String>? endpoints,
    List<String>? domains,
    List<String>? oss,
    List<String>? reports,
    String? goflyCode,
    String? goflyApi,
    String? goflyApiBackup,
    String? sensorsApi,
    String? featureprobeApi,
  }) {
    return LineHttpDnsModelEntity()
      ..dnsId = dnsId ?? this.dnsId
      ..dnsToken = dnsToken ?? this.dnsToken
      ..endpoints = endpoints ?? this.endpoints
      ..domains = domains ?? this.domains
      ..oss = oss ?? this.oss
      ..reports = reports ?? this.reports
      ..goflyCode = goflyCode ?? this.goflyCode
      ..goflyApi = goflyApi ?? this.goflyApi
      ..goflyApiBackup = goflyApiBackup ?? this.goflyApiBackup
      ..sensorsApi = sensorsApi ?? this.sensorsApi
      ..featureprobeApi = featureprobeApi ?? this.featureprobeApi;
  }
}
