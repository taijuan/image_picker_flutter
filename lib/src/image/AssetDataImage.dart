import 'dart:typed_data';
import 'dart:ui' as ui show Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/model/AssetData.dart';
import 'package:image_picker_flutter/src/utils/Utils.dart';

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
    Uint8List bytes = await Utils.channel.invokeMethod(
      'toUInt8List',
      [
        data.id,
        data.isImage,
        width,
        height,
      ],
    );
    if (bytes == null || bytes.lengthInBytes == 0) return null;
    return await PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final AssetDataImage typedOther = other;
    return data.path == typedOther.data.path && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(data.path, scale);

  @override
  String toString() => '$runtimeType("${data.path}", scale: $scale)';
}
