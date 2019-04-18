# Image Picker plugin for Flutter

[![pub package](https://img.shields.io/pub/v/image_picker_flutter.svg)](https://pub.dartlang.org/packages/image_picker_flutter)

A Flutter plugin for iOS and Android for picking images from the image library.

## Installation

First, add `image_picker` as a [dependency in your pubspec.yaml file]

### iOS

Add the following keys to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor.

### Android

Add the following permission to your manifest:

* `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

### Example

``` dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/ImagePicker.dart';
import 'package:image_picker/image/AssetDataImage.dart';
import 'package:image_picker/model/AssetData.dart';
import 'package:image_picker/utils/Utils.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<AssetData> _data = [];

  @override
  void initState() {
    if (Platform.isAndroid) {
      PermissionHandler().requestPermissions([PermissionGroup.storage]);
    }
    if (Platform.isIOS) {
      PermissionHandler().requestPermissions([PermissionGroup.photos]);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Center(
          child: Text("Demo"),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          return Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              Image(
                image: AssetDataImage(_data[index]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              iconVideo(_data[index]),
            ],
          );
        },
        itemCount: _data.length,
      ),
      bottomNavigationBar: Container(
        color: Colors.grey,
        height: 48 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        alignment: AlignmentDirectional.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            RawMaterialButton(
              onPressed: () {
                ImagePicker.mulPicker(
                  context,
                  data: _data,
                  mulCallback: (data) {
                    setState(() {
                      _data = data;
                    });
                  },
                );
              },
              fillColor: Colors.blue,
              child: Text("MulImagePikcer"),
            ),
            RawMaterialButton(
              onPressed: () {
                ImagePicker.singlePicker(context, singleCallback: (data) {
                  setState(() {
                    _data
                      ..removeWhere((a) => a == data)
                      ..add(data);
                  });
                });
              },
              fillColor: Colors.blue,
              child: Text("SingleImagePikcer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget iconVideo(AssetData data) {
    if (data.isImage) {
      return Container(
        width: 0,
        height: 0,
      );
    }
    return Icon(
      Utils.video,
      color: Colors.blue,
    );
  }
}

```
