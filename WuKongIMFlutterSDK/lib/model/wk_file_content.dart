import 'package:wukongimfluttersdk/model/wk_media_message_content.dart';
import 'package:wukongimfluttersdk/model/wk_message_content.dart';
import 'package:wukongimfluttersdk/type/const.dart';

class WKFileContent extends WKMediaMessageContent {

  String? mimeType;

  String name;

  num size;

  WKFileContent(this.name, this.size, {String? mimeType}) {
    contentType = WkMessageContentType.file;
  }

  @override
  Map<String, dynamic> encodeJson() {
    return {
      'name': name,
      'size': size,
      'mimeType': mimeType,
      'url': url,
      'localPath': localPath
    };
  }

  @override
  WKMessageContent decodeJson(Map<String, dynamic> json) {
    name = readString(json, 'name');
    size = readInt(json, 'size');
    mimeType = readString(json, 'mimeType');
    url = readString(json, 'url');
    localPath = readString(json, 'localPath');
    return this;
  }

  @override
  String displayText() {
    return '[文件]';
  }

  @override
  String searchableWord() {
    return '[文件]';
  }
}