class AssetData {
  ///ios id与path不一致，Android id与path相同
  String id;
  String name;
  String path;
  String mimeType;
  int time;
  int width;
  int height;

  AssetData.fromJson(dynamic json) {
    id = json["id"];
    name = json["name"];
    path = json["path"];
    mimeType = json["mimeType"];
    time = json["time"];
    width = json["width"];
    height = json["height"];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "path": path,
      "mimeType": mimeType,
      "time": time,
      "width": width,
      "height": height,
    };
  }

  bool get isImage => mimeType.contains("image");

  @override
  bool operator ==(Object other) {
    if (other is AssetData && runtimeType == other.runtimeType) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
