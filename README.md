# image_picker_flutter [![pub package](https://img.shields.io/pub/v/image_picker_flutter.svg)](https://pub.dartlang.org/packages/image_picker_flutter)
## 功能介绍

- [x] 该插件目前支持IOS(8-13)、Android(16-29)
- [x] 支持单选、多选
- [x] 提供拍照、视频录制功能
- [x] 支持多种图片格式PNG、JPG、GIF等,Flutter不支持的图片格式通过IOS、Android原生方法提供支持
- [x] 支持多种视频格式，视频预览图通过IOS、Android原生方法提供支持
- [x] 所用资源都提供File的绝对路径
- [ ] 不支持原图预览
- [ ] 不支持视频播放
- [ ] 不支持IOS、Android动态权限、需要使用之前自行权限获取，建议使用[permission_handler](https://github.com/BaseflowIT/flutter-permission-handler)
- [ ] ...

## Demo动图(有那么点不清晰)
![image](https://github.com/taijuan/image_picker_flutter/blob/master/image.gif)

## 使用说明

### dependencies in flutter

```

dependencies:
  image_picker_flutter: ^1.3.3
  
```

### iOS 权限

``` 

<key>NSPhotoLibraryUsageDescription</key>
<string>使用图片</string>
<key>NSCameraUsageDescription</key>
<string>照相</string>
<key>NSMicrophoneUsageDescription</key>
<string>录音</string>

```
### Android 权限

``` Android Permissions

<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />

```
 

## Demo 应用

### [Android APP](https://fir.im/qfb8)

### IOS APP 因发布原因暂不提供、可以下载代码编译安装




## API 介绍
- [ImagePicker](https://github.com/taijuan/image_picker_flutter/blob/master/lib/src/image_picker.dart)
  - （单选）singlePicker
  - （多选）mulPicker
  - （拍照）takePicture
  - （视频录制）takeVideo


## 序言
    - Flutter越做越强大！！！
    - image_picker_flutter功能越来越完善！！！
    - 开源加油！！！
