import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show instantiateImageCodec, Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/model/asset_data.dart';
import 'package:image_picker_flutter/src/utils.dart';

class AssetDataImage extends ImageProvider<AssetDataImage> {
  const AssetDataImage(
    this.data, {
    this.width = 360,
    this.height = 360,
    this.scale = 1.0,
  })  : assert(data != null),
        assert(scale != null);

  final AssetData data;
  final int width, height;
  final double scale;

  @override
  Future<AssetDataImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetDataImage>(this);
  }

  @override
  ImageStreamCompleter load(AssetDataImage key) {
    return MultiFrameImageStreamCompleter(
        codec: _loadAsync(key),
        scale: key.scale,
        informationCollector: () sync* {
          yield DiagnosticsProperty<ImageProvider>('Image provider', this);
          yield DiagnosticsProperty<AssetDataImage>('Image key', this);
        });
  }

  Future<ui.Codec> _loadAsync(AssetDataImage key) async {
    assert(key == this);
    Utils.log("_loadAsync start");
    Uint8List bytes;
    if (Platform.isIOS && Utils.isEmpty(data.path)) {
      ///ios根据id查找文件绝对路径
      await Utils.convertSingleData(data);
      Utils.log("_loadAsync start ios path");
      Utils.log("_loadAsync start ios path" + data.path);
    }
    File file = File(data.path);

    ///判断文件是否存在
    if (!await file.exists()) {
      return null;
    }

    ///判断是否是支持的文件格式
    if (Utils.isSupportImageFormatString(await file.openRead(0, 3).first)) {
      ///支持
      bytes = await file.readAsBytes();
    } else {
      ///不支持走原生方式，获取的是jpg
      bytes = await Utils.channel.invokeMethod(
        'toUInt8List',
        [
          data.id,
          data.isImage,
          width,
          height,
        ],
      );
    }
    if (bytes == null || bytes.lengthInBytes == 0) return null;
    return await ui.instantiateImageCodec(
      bytes,
      targetWidth: width,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final AssetDataImage typedOther = other;
    return data == typedOther.data &&
        scale == typedOther.scale &&
        width == typedOther.width &&
        height == typedOther.height;
  }

  @override
  int get hashCode => hashValues(data, width, height, scale);

  @override
  String toString() =>
      '$runtimeType("$data", width: $width,heght: $height,scale: $scale)';
}
