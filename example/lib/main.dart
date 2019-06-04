import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_flutter/image_picker_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );
  SystemChrome.setSystemUIOverlayStyle(dark);
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<AssetData> _data = [];

  @override
  void initState() {
    ImagePicker.debug(true);
    if (Platform.isAndroid) {
      PermissionHandler().requestPermissions([
        PermissionGroup.storage,
        PermissionGroup.camera,
      ]);
    }
    if (Platform.isIOS) {
      PermissionHandler().requestPermissions([
        PermissionGroup.photos,
        PermissionGroup.camera,
      ]);
    }
    PaintingBinding.instance.imageCache
      ..maximumSize = 1000
      ..maximumSizeBytes = 500 << 20;
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
                image: AssetDataImage(
                  _data[index],
                  targetWidth: Utils.width2px(context, ratio: 3),
                  targetHeight: Utils.width2px(context, ratio: 3),
                ),
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
        height: MediaQuery.of(context).size.width / 4 +
            MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        alignment: AlignmentDirectional.center,
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 4,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
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
            RawMaterialButton(
              onPressed: () {
                ImagePicker.takePicture((a) {
                  setState(() {
                    _data.add(a);
                  });
                });
              },
              fillColor: Colors.blue,
              child: Text("takePicture"),
            ),
            RawMaterialButton(
              onPressed: () {
                ImagePicker.takeVideo((a) {
                  setState(() {
                    _data.add(a);
                  });
                });
              },
              fillColor: Colors.blue,
              child: Text("takeVideo"),
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
