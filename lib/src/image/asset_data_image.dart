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
  ImageStreamCompleter load(AssetDataImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>('Image provider', this);
        yield DiagnosticsProperty<AssetDataImage>('Image key', key);
      },
    );
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
      return await ui.instantiateImageCodec(bytes);
    }
    bytes = await file.readAsBytes();
    if (bytes == null || bytes.lengthInBytes == 0) return null;
    if (targetWidth == null && targetHeight == null) {
      return await ui.instantiateImageCodec(bytes);
    } else if (targetWidth <= 0 && targetHeight == null) {
      return await ui.instantiateImageCodec(bytes);
    } else if (targetWidth > 0 && targetHeight == null) {
      return await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth > data.width ? targetWidth : -1,
      );
    } else if (targetWidth == null && targetHeight <= 0) {
      return await ui.instantiateImageCodec(bytes);
    } else if (targetWidth == null && targetHeight > 0) {
      return await ui.instantiateImageCodec(
        bytes,
        targetHeight: targetHeight > data.height ? targetHeight : -1,
      );
    } else {
      int w = data.width;
      int h = data.height;
      double wd = w / targetWidth.toDouble();
      double hd = h / targetHeight.toDouble();
      double be = 1;
      if (wd >= 1 && hd >= 1) {
        be = wd >= hd ? wd : hd;
      }
      w = w ~/ be;
      h = h ~/ be;
      Utils.log("width：${data.width},height：${data.height}");
      Utils.log("targetWidth：$targetWidth,targetHeight：$targetHeight");
      Utils.log("w：$w,h：$h");
      return await ui.instantiateImageCodec(
        bytes,
        targetWidth: w,
        targetHeight: h,
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
