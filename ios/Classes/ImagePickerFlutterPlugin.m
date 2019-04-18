#import "ImagePickerFlutterPlugin.h"
#import <image_picker_flutter/image_picker_flutter-Swift.h>

@implementation ImagePickerFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImagePickerFlutterPlugin registerWithRegistrar:registrar];
}
@end
