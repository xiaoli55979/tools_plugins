import 'package:line_detection_plugin/generated/json/base/json_convert_content.dart';
import 'package:line_detection_plugin/src/model/http_dns_entity.dart';

HttpDnsEntity $HttpDnsEntityFromJson(Map<String, dynamic> json) {
  final HttpDnsEntity httpDnsEntity = HttpDnsEntity();
  final int? test = jsonConvert.convert<int>(json['test']);
  if (test != null) {
    httpDnsEntity.test = test;
  }
  return httpDnsEntity;
}

Map<String, dynamic> $HttpDnsEntityToJson(HttpDnsEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['test'] = entity.test;
  return data;
}

extension HttpDnsEntityExtension on HttpDnsEntity {
  HttpDnsEntity copyWith({
    int? test,
  }) {
    return HttpDnsEntity()..test = test ?? this.test;
  }
}
