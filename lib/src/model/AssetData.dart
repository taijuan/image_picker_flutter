import 'dart:io';

class AssetData {
  String id;
  String name;
  String path;
  String mimeType;
  int time;

  AssetData.fromJson(dynamic json) {
    id = json["id"];
    name = json["name"];
    path = json["path"];
    mimeType = json["mimeType"];
    time = json["time"];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "path": path,
      "mimeType": mimeType,
      "time": time,
    };
  }

  bool get isImage => mimeType.contains("image");

  @override
  bool operator ==(Object other) {
    if (other is AssetData && runtimeType == other.runtimeType) {
      if (Platform.isIOS) {
        return id == other.id;
      } else {
        return path == other.path;
      }
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    if (id != null) {
      return id.hashCode;
    } else {
      return path.hashCode;
    }
  }
}
