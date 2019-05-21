import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/ImagePicker.dart';
import 'package:image_picker_flutter/src/model/AssetData.dart';

class Utils {
  static const String packageName = "image_picker_flutter";

  static const MethodChannel channel = const MethodChannel('image_picker');

  ///获取图片视频资源
  static Future<List<AssetData>> getImages(ImagePickerType type) async {
    final List<dynamic> a = await channel.invokeMethod(
      'getImages',
      Utils.getType(type),
    );
    final List<AssetData> data = a.map(
      (a) {
        AssetData b = AssetData.fromJson(a);
        return b;
      },
    ).toList();

    data.sort((a, b) {
      return b.time.compareTo(a.time);
    });
    return data;
  }

  static Future<List<AssetData>> convertMulData(List<AssetData> data) async {
    if (Platform.isIOS) {
      List<dynamic> aa = await Future.wait(data.map((a) {
        return channel.invokeMethod("getFilePath", [a.id, a.isImage]);
      }));
      for (var i = 0; i < data.length; i++) {
        AssetData a = data[i];
        String path = aa[i] ?? "";
        a.path = path;
        a.name = path.split("/").last;
        a.mimeType = "${a.mimeType}${path.split(".").last.toLowerCase()}";
        a.path = a.path.replaceAll("file:///", "");
      }
    }
    return data;
  }

  static Future<AssetData> convertSingleData(AssetData data) async {
    if (Platform.isIOS) {
      data.path =
          await channel.invokeMethod("getFilePath", [data.id, data.isImage]);
    }
    return data;
  }

  ///
  static void cancelAll() async {
    await channel.invokeMethod("cancelAll");
  }

  static Future<AssetData> takePicture() async {
    dynamic a = await channel.invokeMethod("takePicture");
    AssetData b = await convertSingleData(AssetData.fromJson(a));
    return b;
  }

  static Future<AssetData> takeVideo() async {
    dynamic a = await channel.invokeMethod("takeVideo");
    AssetData b = await convertSingleData(AssetData.fromJson(a));
    return b;
  }

  static final AssetImage placeholder = AssetImage(
    "images/placeholder.webp",
    package: packageName,
  );

  static final IconData back = IconData(
    0xe62a,
    fontFamily: 'iconfont',
    fontPackage: packageName,
  );
  static final IconData save = IconData(
    0xe601,
    fontFamily: 'iconfont',
    fontPackage: packageName,
  );
  static final IconData video = IconData(
    0xe641,
    fontFamily: 'iconfont',
    fontPackage: packageName,
  );

  static int getType(ImagePickerType type) {
    switch (type) {
      case ImagePickerType.onlyImage:
        return 1;
      case ImagePickerType.onlyVideo:
        return 2;
      case ImagePickerType.imageAndVideo:
        return 3;
    }
    return 3;
  }

  static int width2px(BuildContext context, {double ratio = 1}) {
    int a = MediaQuery.of(context).size.width *
        MediaQuery.of(context).devicePixelRatio ~/
        ratio;
    print(a);
    return a;
  }
}
