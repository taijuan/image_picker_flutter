class AssetData {
  String id;
  String name;
  String path;
  int size;
  String mimeType;
  int width;
  int height;
  int time;

  AssetData.fromJson(dynamic json) {
    id = json["id"];
    name = json["name"];
    path = json["path"];
    size = json["size"];
    mimeType = json["mimeType"];
    width = json["width"];
    height = json["height"];
    time = json["time"];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "path": path,
      "size": size,
      "mimeType": mimeType,
      "width": width,
      "height": height,
      "time": time,
    };
  }

  bool get isImage => mimeType.contains("image");

  @override
  bool operator ==(Object other) {
    if (other is AssetData && runtimeType == other.runtimeType) {
      if (id != null) {
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
