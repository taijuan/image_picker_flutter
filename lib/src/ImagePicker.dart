import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/model/AssetData.dart';
import 'package:image_picker_flutter/src/page/MulImagePickerPage.dart';
import 'package:image_picker_flutter/src/page/SingleImagePickerPage.dart';

typedef MulCallback = void Function(List<AssetData>);

typedef SingleCallback = void Function(AssetData);

class ImagePicker {
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
