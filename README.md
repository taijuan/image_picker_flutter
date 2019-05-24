# Image Picker plugin for Flutter

[![pub package](https://img.shields.io/pub/v/image_picker_flutter.svg)](https://pub.dartlang.org/packages/image_picker_flutter)

A Flutter plugin for iOS and Android for picking images from the image library.

 <img src="screenshot/1.jpg" alt="screenshot1" width ="30%"/> <img src="screenshot/2.jpg" alt="screenshot2" width ="30%"/>


## Installation

First, add `image_picker_flutter` as a [dependency in your pubspec.yaml file]

``` aidl

dependencies:
  image_picker_flutter: ^1.0.5+1
  
```

### iOS

Add the following keys to your Info.plist:

``` IOS Keys

<key>NSPhotoLibraryUsageDescription</key>
<string>使用图片</string>
<key>NSCameraUsageDescription</key>
<string>照相</string>
<key>NSMicrophoneUsageDescription</key>
<string>录音</string>

```
### Android

Add the following permission to your manifest:

``` Android Permissions

<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />

```
 

### Install app Android  

[apk download](https://fir.im/qfb8)



### API

```
 import 'package:flutter/material.dart';
 import 'package:flutter/widgets.dart';
 import 'package:image_picker_flutter/src/model/asset_data.dart';
 import 'package:image_picker_flutter/src/page/mul_image_picker_page.dart';
 import 'package:image_picker_flutter/src/page/single_image_picker_page.dart';
 import 'package:image_picker_flutter/src/utils.dart';
 
 typedef MulCallback = void Function(List<AssetData>);
 
 typedef SingleCallback = void Function(AssetData);
 
 typedef Callback = void Function(AssetData);
 
 class ImagePicker {
   ImagePicker._();
 
   static debug(bool isDebug) {
     Utils.isDebug = isDebug;
   }
 
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
 
 ///文字基类
 class Language {
   String get title => "Gallery";
 
   String get showToast => "Only ### images can be selected";
 }
```


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
