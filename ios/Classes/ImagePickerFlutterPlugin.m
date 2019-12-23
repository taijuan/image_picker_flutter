#import "ImagePickerFlutterPlugin.h"
#if __has_include(<image_picker_flutter/image_picker_flutter-Swift.h>)
#import <image_picker_flutter/image_picker_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "image_picker_flutter-Swift.h"
#endif

@implementation ImagePickerFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImagePickerFlutterPlugin registerWithRegistrar:registrar];
}
@end
