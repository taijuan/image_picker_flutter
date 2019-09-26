import Flutter
import UIKit
import AVFoundation
import Photos
import MobileCoreServices

public class SwiftImagePickerFlutterPlugin: NSObject, FlutterPlugin ,UINavigationControllerDelegate,UIImagePickerControllerDelegate{
    let manager:PHCachingImageManager = PHCachingImageManager.default() as! PHCachingImageManager;
    var result: FlutterResult? = nil;
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "image_picker", binaryMessenger: registrar.messenger());
        let instance = SwiftImagePickerFlutterPlugin();
        registrar.addMethodCallDelegate(instance, channel: channel);
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
            cancelAll(result: result);
        }else if(call.method == "takePicture"){
            takePicker(isVideo:false,result: result);
        }else if(call.method == "takeVideo"){
            takePicker(isVideo:true,result: result)
        }else{
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getImages(type:Int,result:@escaping FlutterResult){
        DispatchQueue.main.async {
            var arr = Array<Dictionary<String,Any>>();
            if(type == 1 || type == 3){
                let all =  PHAsset.fetchAssets(with: .image, options: nil);
                for index in 0..<all.count{
                    let a = all[index];
                    var d:Dictionary<String,Any> = Dictionary<String,Any>();
                    d.updateValue(a.localIdentifier, forKey: "id")
                    d.updateValue("image/",forKey: "mimeType");
                    d.updateValue(
                        Int(a.creationDate!.timeIntervalSince1970),
                        forKey: "time");
                    d.updateValue(a.pixelWidth,forKey: "width");
                    d.updateValue(a.pixelHeight, forKey: "height");
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
                    d.updateValue(
                        Int(a.creationDate!.timeIntervalSince1970 ),
                        forKey: "time");
                    d.updateValue(a.pixelWidth,forKey: "width");
                    d.updateValue(a.pixelHeight, forKey: "height");
                    arr.append(d);
                }
            }
            result(arr);
        }
    }
    
    private func getFilePath(id:String,isImage:Bool,result:@escaping FlutterResult){
        if(isImage){
            let  asset:PHAsset = PHAsset.fetchAssets(
                withLocalIdentifiers: [id],
                options: nil
                ).firstObject!;
            let options2 = PHContentEditingInputRequestOptions()
            options2.isNetworkAccessAllowed = true
            asset.requestContentEditingInput(with: options2){(input, info) in
                result(input?.fullSizeImageURL?.path ?? "")
            }
        }else{
            let  asset:PHAsset = PHAsset.fetchAssets(
                withLocalIdentifiers: [id],
                options: nil
                ).firstObject!;
            manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: {(asset,v,any) in
                let  url = (asset as? AVURLAsset)?.url.absoluteString
                result(url ?? "");
            });
        }
    }
    
    private func imageToUInt8List(id:String,width:Int,height:Int,result:@escaping FlutterResult){
        let  asset:PHAsset? = PHAsset.fetchAssets(
            withLocalIdentifiers: [id],
            options: nil
            ).firstObject;
        if(asset != nil){
            manager.requestImage(for: asset!, targetSize: CGSize(width: width, height: height), contentMode: .aspectFit, options: nil, resultHandler: {(image,any) in
                if(image == nil){
                    result(nil);
                }else{
                    result(image?.jpegData(compressionQuality: 75));
                }
            });
        }
    }
    
    private func cancelAll(result:@escaping FlutterResult){
        manager.stopCachingImagesForAllAssets();
        result(true);
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[.mediaType] as! String;
        if(mediaType.contains("image")){
            let image:UIImage?  = info[.originalImage] as? UIImage;
            if(image != nil){
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from:image!);
                    print("kaishi0");
                }, completionHandler: {isSuccess, e in
                    if(isSuccess){
                        print("zuiweng  success");
                        let a = PHAsset.fetchAssets(with: .image, options: nil).lastObject;
                        if(a != nil){
                            var d = Dictionary<String,Any>();
                            d.updateValue(a!.localIdentifier, forKey: "id")
                            d.updateValue("image/",forKey: "mimeType");
                            d.updateValue(
                                Int(a!.creationDate!.timeIntervalSince1970),
                                forKey: "time");
                            d.updateValue(a!.pixelWidth,forKey: "width");
                            d.updateValue(a!.pixelHeight, forKey: "height");
                            self.result?(d);
                            self.result = nil;
                        }
                    }
                    picker.dismiss(animated: true, completion: nil);
                });
            }
        }else if(mediaType.contains("movie")){
            let videoUrl:NSURL? = info[.mediaURL] as? NSURL;
            if(videoUrl != nil){
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(
                        atFileURL: videoUrl!.absoluteURL!)
                },completionHandler:{isSuccess ,e in
                    if(isSuccess){
                        print("zuiweng  success");
                        let a = PHAsset.fetchAssets(with: .video, options: nil).lastObject;
                        if(a != nil){
                            var d = Dictionary<String,Any>();
                            d.updateValue(a!.localIdentifier, forKey: "id")
                            d.updateValue("video/",forKey: "mimeType");
                            d.updateValue(
                                Int(a!.creationDate!.timeIntervalSince1970),
                                forKey: "time")
                            d.updateValue(a!.pixelWidth,forKey: "width");
                            d.updateValue(a!.pixelHeight, forKey: "height");
                            self.result?(d);
                            self.result = nil;
                        }
                    }
                    picker.dismiss(animated: true, completion: nil);
                });
            }
        }else{
            picker.dismiss(animated: true, completion: nil);
        }
        
    }
    
    func takePicker(isVideo:Bool,result:@escaping FlutterResult){
        self.result = result;
        if (UIImagePickerController.isSourceTypeAvailable(.camera)){
            let  cameraPicker = UIImagePickerController();
            cameraPicker.delegate = self;
            cameraPicker.sourceType = .camera;
            cameraPicker.allowsEditing = false;
            if(isVideo){
                cameraPicker.mediaTypes = [kUTTypeMovie as String];
                cameraPicker.videoQuality = .typeIFrame1280x720;
            }else{
                cameraPicker.mediaTypes = [kUTTypeImage as String];
            }
            UIApplication.shared.windows.last?.rootViewController?.present(
                cameraPicker,
                animated: true,
                completion: nil
            );
        }else{
            print("camera is nil");
        }
    }
}
