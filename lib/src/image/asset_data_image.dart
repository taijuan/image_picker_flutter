import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/model/asset_data.dart';
import 'package:image_picker_flutter/src/utils.dart';

class AssetDataImage extends ImageProvider<AssetDataImage> {
  const AssetDataImage(
    this.data, {
    this.targetWidth,
    this.targetHeight,
    this.scale = 1.0,
  })  : assert(data != null),
        assert(scale != null);

  final AssetData data;
  final int targetWidth, targetHeight;
  final double scale;

  @override
  Future<AssetDataImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetDataImage>(this);
  }

  @override
  ImageStreamCompleter load(AssetDataImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>('Image provider', this);
        yield DiagnosticsProperty<AssetDataImage>('Image key', key);
      },
    );
  }

  Future<ui.Codec> _loadAsync(
      AssetDataImage key, DecoderCallback decode) async {
    assert(key == this);

    Uint8List bytes;
    File file = File(data.path);

    ///判断文件是否存在
    if (!await file.exists()) {
      return null;
    }

    ///判断是否是支持的文件格式
    if (!Utils.isSupportImageFormatString(await file.openRead(0, 3).first)) {
      ///不支持走原生方式，获取的是jpg
      bytes = await Utils.channel.invokeMethod(
        'toUInt8List',
        [
          data.id,
          data.isImage,
          targetWidth,
          targetHeight,
        ],
      );
      return await decode(bytes);
    }
    bytes = await file.readAsBytes();
    if (bytes == null || bytes.lengthInBytes == 0) return null;
    if (targetWidth == null && targetHeight == null) {
      return await decode(bytes);
    } else if (targetWidth <= 0 && targetHeight == null) {
      return await decode(bytes);
    } else if (targetWidth > 0 && targetHeight == null) {
      return await decode(
        bytes,
        cacheWidth: targetWidth > data.width ? targetWidth : -1,
      );
    } else if (targetWidth == null && targetHeight <= 0) {
      return await decode(bytes);
    } else if (targetWidth == null && targetHeight > 0) {
      return await decode(
        bytes,
        cacheHeight: targetHeight > data.height ? targetHeight : -1,
      );
    } else {
      int w = data.width;
      int h = data.height;
      double wd = w / targetWidth.toDouble();
      double hd = h / targetHeight.toDouble();
      double be = max(1, max(wd, hd));
      w = w ~/ be;
      h = h ~/ be;
      Utils.log("width：${data.width},height：${data.height}");
      Utils.log("targetWidth：$targetWidth,targetHeight：$targetHeight");
      Utils.log("w：$w,h：$h");
      return await decode(
        bytes,
        cacheWidth: w,
        cacheHeight: h,
      );
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final AssetDataImage typedOther = other;
    return data == typedOther.data &&
        scale == typedOther.scale &&
        targetWidth == typedOther.targetWidth &&
        targetHeight == typedOther.targetHeight;
  }

  @override
  int get hashCode => hashValues(data, targetWidth, targetHeight, scale);

  @override
  String toString() =>
      '$runtimeType("$data", targetWidth: $targetWidth,targetHeight: $targetHeight,scale: $scale)';
}
