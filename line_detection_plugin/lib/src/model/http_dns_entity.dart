import 'dart:convert';

import 'package:line_detection_plugin/generated/json/base/json_field.dart';
import 'package:line_detection_plugin/generated/json/http_dns_entity.g.dart';

export 'package:line_detection_plugin/generated/json/http_dns_entity.g.dart';

@JsonSerializable()
class HttpDnsEntity {
  late int test = 0;

  HttpDnsEntity();

  factory HttpDnsEntity.fromJson(Map<String, dynamic> json) => $HttpDnsEntityFromJson(json);

  Map<String, dynamic> toJson() => $HttpDnsEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
