import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/ImagePicker.dart';
import 'package:image_picker_flutter/src/model/AssetData.dart';

class Utils {
  ///插件包名，这个很重要
  static const String packageName = "image_picker_flutter";

  ///插件通道
  static const MethodChannel channel = const MethodChannel('image_picker');

  ///日志开关
  static bool isDebug = false;

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

  ///多选数据组合
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

  ///单选数据组合
  static Future<AssetData> convertSingleData(AssetData data) async {
    if (Platform.isIOS) {
      data.path =
          await channel.invokeMethod("getFilePath", [data.id, data.isImage]);
    }
    return data;
  }

  ///取消任务
  static void cancelAll() async {
    await channel.invokeMethod("cancelAll");
  }

  ///拍照
  static Future<AssetData> takePicture() async {
    dynamic a = await channel.invokeMethod("takePicture");
    AssetData b = await convertSingleData(AssetData.fromJson(a));
    return b;
  }

  ///录制视频
  static Future<AssetData> takeVideo() async {
    dynamic a = await channel.invokeMethod("takeVideo");
    AssetData b = await convertSingleData(AssetData.fromJson(a));
    return b;
  }

  ///默认的图片加载loading
  static final AssetImage placeholder = AssetImage(
    "images/placeholder.webp",
    package: packageName,
  );

  ///默认的返回键icon
  static final IconData back = IconData(
    0xe62a,
    fontFamily: 'iconfont',
    fontPackage: packageName,
  );

  ///默认的保存icon
  static final IconData save = IconData(
    0xe601,
    fontFamily: 'iconfont',
    fontPackage: packageName,
  );

  ///视频标签
  static final IconData video = IconData(
    0xe641,
    fontFamily: 'iconfont',
    fontPackage: packageName,
  );

  ///image_picker请求类型
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

  ///屏幕宽度(单位pix)
  static int width2px(BuildContext context, {double ratio = 1}) {
    int a = MediaQuery.of(context).size.width *
        MediaQuery.of(context).devicePixelRatio ~/
        ratio;
    return a;
  }

  ///图片文件直接使用判断，目前支持jpg,png,webp,gif
  static bool isSupportImageFormatString(Uint8List bytes) {
    String format = imageFormatString(bytes);
    log(format);
    return format != "unknow";
  }

  ///数据流判断文件类型
  static String imageFormatString(Uint8List bytes) {
    if (bytes == null || bytes.isEmpty) {
      return "unknow";
    }
    int format = bytes[0];
    if (format == 0xff) {
      return ".jpg";
    } else if (format == 0x89) {
      return ".png";
    } else if (format == 0x47) {
      return ".gif";
    } else if (format == 0x52) {
      return ".webp";
    } else {
      return "unknow";
    }
  }

  ///日志输出
  static log(dynamic o) {
    print(o);
  }
}
