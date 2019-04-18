import Flutter
import UIKit
import Photos

public class SwiftImagePickerFlutterPlugin: NSObject, FlutterPlugin {
  let manager:PHCachingImageManager = PHCachingImageManager.init();
      public static func register(with registrar: FlutterPluginRegistrar) {
          let channel = FlutterMethodChannel(name: "image_picker", binaryMessenger: registrar.messenger())
          let instance = SwiftImagePickerFlutterPlugin()
          registrar.addMethodCallDelegate(instance, channel: channel)
      }

      public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
          if(call.method == "getImages"){
              getImages(type: call.arguments as! Int,result: result);
          }else if(call.method == "getFilePath"){
              let arr:Array<Any> = call.arguments as! Array<Any>;
              getFilePath(id: arr[0] as! String ,isImage:arr[1] as! Bool, result: result);
          }else if(call.method == "toUInt8List"){
              let arr = call.arguments as! Array<Any>;
              imageToUInt8List(id: arr[0] as! String,width: arr[2] as! Int ,height: arr[3] as! Int, result: result)
          }else if(call.method == "cancelAll"){
              cancelAll();
          }else{
              result(FlutterMethodNotImplemented)
          }
      }

      private func getImages(type:Int,result:@escaping FlutterResult){
          var arr = Array<Dictionary<String,Any>>();
          if(type == 1 || type == 3){
              let all =  PHAsset.fetchAssets(with: .image, options: nil);
              for index in 0..<all.count{
                  let a = all[index];
                  var d:Dictionary<String,Any> = Dictionary<String,Any>();
                  d.updateValue(a.localIdentifier, forKey: "id")
                  d.updateValue("image/",forKey: "mimeType");
                  d.updateValue(a.pixelWidth,forKey: "width");
                  d.updateValue(a.pixelHeight, forKey: "height");
                  d.updateValue(
                      Int(a.creationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970),
                      forKey: "time")
                  arr.append(d);
              }
          }
          if(type == 2 || type == 3){
              let all =  PHAsset.fetchAssets(with: .video, options: nil);
              for index in 0..<all.count{
                  let a = all[index];
                  var d:Dictionary<String,Any> = Dictionary<String,Any>();
                  d.updateValue(a.localIdentifier, forKey: "id")
                  d.updateValue("video/",forKey: "mimeType");
                  d.updateValue(a.pixelWidth,forKey: "width");
                  d.updateValue(a.pixelHeight, forKey: "height");
                  d.updateValue(
                      Int(a.creationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970),
                      forKey: "time")
                  arr.append(d);
              }
          }
          result(arr);
      }

      private func getFilePath(id:String,isImage:Bool,result:@escaping FlutterResult){
          if(isImage){
              let  asset:PHAsset = PHAsset.fetchAssets(
                  withLocalIdentifiers: [id],
                  options: nil
                  ).firstObject!;
              manager.requestImageData(for: asset, options: nil, resultHandler:{(data,str,x,any) in
                  let url = (any?["PHImageFileURLKey"] as? NSURL)?.absoluteString
                  result(url);
              });
          }else{
              let  asset:PHAsset = PHAsset.fetchAssets(
                  withLocalIdentifiers: [id],
                  options: nil
                  ).firstObject!;
              manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: {(asset,v,any) in
                  let  url = (asset as? AVURLAsset)?.url.absoluteString
                  result(url);
              });
          }
      }

      private func imageToUInt8List(id:String,width:Int,height:Int,result:@escaping FlutterResult){
          let  asset:PHAsset = PHAsset.fetchAssets(
              withLocalIdentifiers: [id],
              options: nil
              ).firstObject!;
          manager.requestImage(for: asset, targetSize: CGSize(width: width, height: height), contentMode: .aspectFit, options: nil, resultHandler: {(image,any) in
              if(image == nil){
                  result(nil);
              }else{
                result(image?.jpegData(compressionQuality: 75));
              }
          })

      }

      private func cancelAll(){
          manager.stopCachingImagesForAllAssets();
      }
}
