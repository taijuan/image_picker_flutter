import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/model/AssetData.dart';
import 'package:image_picker_flutter/src/page/MulImagePickerPage.dart';
import 'package:image_picker_flutter/src/page/SingleImagePickerPage.dart';

import 'utils/Utils.dart';

typedef MulCallback = void Function(List<AssetData>);

typedef SingleCallback = void Function(AssetData);

typedef Callback = void Function(AssetData);

class ImagePicker {
  ///单选图片
  static void singlePicker(
    BuildContext context, {
    ImagePickerType type = ImagePickerType.imageAndVideo,
    Language language,
    ImageProvider placeholder,
    Widget title,
    Widget back,
    Decoration decoration,
    Color appBarColor = Colors.blue,
    SingleCallback singleCallback,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SingleImagePickerPage(
              type: type,
              language: language ?? Language(),
              placeholder: placeholder,
              decoration: decoration,
              appBarColor: appBarColor ?? Colors.blue,
              title: title,
              back: back,
            ),
      ),
    )..then((data) {
        if (data != null && singleCallback != null) {
          singleCallback(data);
        }
      });
  }

  ///多选图片
  static void mulPicker(
    BuildContext context, {
    List<AssetData> data,
    ImagePickerType type = ImagePickerType.imageAndVideo,
    int limit = 9,
    Language language,
    ImageProvider placeholder,
    Widget title,
    Widget back,
    Widget menu,
    Decoration decoration,
    Color appBarColor = Colors.blue,
    MulCallback mulCallback,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MulImagePickerPage(
              selectedData: data,
              type: type,
              limit: limit,
              appBarColor: appBarColor ?? Colors.blue,
              language: language ?? Language(),
              placeholder: placeholder,
              decoration: decoration,
              title: title,
              menu: menu,
              back: back,
            ),
      ),
    )..then((data) {
        if (data != null && mulCallback != null) {
          mulCallback(data);
        }
      });
  }

  ///拍照返回图片路径
  static void takePicture(Callback callback) {
    Utils.takePicture().then((a) {
      callback(a);
    });
  }

  ///录像返回图片路径
  static void takeVideo(Callback callback) {
    Utils.takeVideo().then((a) {
      callback(a);
    });
  }
}

enum ImagePickerType {
  onlyImage,
  onlyVideo,
  imageAndVideo,
}

class Language {
  String get title => "Gallery";

  String get showToast => "Only ### images can be selected";
}
