import Flutter
import UIKit
import AVFoundation
import Photos
import MobileCoreServices

public class SwiftImagePickerFlutterPlugin: NSObject, FlutterPlugin ,UINavigationControllerDelegate,UIImagePickerControllerDelegate{
    let manager:PHCachingImageManager = PHCachingImageManager.default() as! PHCachingImageManager;
    var result: FlutterResult? = nil;
    var allImages = Array<Dictionary<String,Any>>();
    var allFolders = Array<String>();
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "image_picker", binaryMessenger: registrar.messenger());
        let instance = SwiftImagePickerFlutterPlugin();
        registrar.addMethodCallDelegate(instance, channel: channel);
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "getFolders"){
            getFolders(type: call.arguments as! Int, result: result)
        }else if(call.method == "getImages"){
            getImages(folder: call.arguments as! String,result: result);
        }else if(call.method == "toUInt8List"){
            let arr = call.arguments as! Array<Any>;
            toUInt8List(id: arr[0] as! String,width: arr[2] as! Int ,height: arr[3] as! Int, result: result)
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
    
    //MARK:获取对应相册数据源
    private func getFolders(type:Int,result:@escaping FlutterResult){
        allImages.removeAll()
        allFolders.removeAll()
        allFolders.append("All")
        DispatchQueue.global(qos: .default).async {
            let fetchOptions = PHFetchOptions()
            if(type == 1){
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            }else if(type == 2 ){
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            }else{}
            let all = PHAsset.fetchAssets(with: fetchOptions);
            for index in 0..<all.count{
                let a = all[index];
                self.allImages.append(self.getPath(asset: a, folder: "All"));
            }
            let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            for index in 0..<albums.count{
                let album = albums[index]
                let folder:String = album.localizedTitle ?? ""
                if(!self.allFolders.contains(folder)){
                    self.allFolders.append(folder)
                }
                let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
                for index in 0..<assets.count{
                    let a = assets[index]
                    self.checkItem(id: a.localIdentifier,folder:folder)
                }
            }
            self.allFolders.append("Other")
            DispatchQueue.main.async {
               result(self.allFolders)
            }
        }
    }
    
    //MARK:相册图片视频逻辑
    private func checkItem(id:String,folder:String){
        let index = allImages.firstIndex { (d) -> Bool in
            let _id:String? = d["id"] as? String
            return _id == id
        }
        if(index != nil){
            var d = allImages[index!]
            allImages.remove(at: index!)
            let oldFolder:String = d["folder"] as? String ?? ""
            d.updateValue("\(oldFolder),\(folder)", forKey: "folder")
            allImages.append(d)
        }
    }
    //MARK:获取对应相册图片视频数据源
    private func getImages(folder:String,result:@escaping FlutterResult){
        if(folder == "All"){
            result(self.allImages)
        }else if(folder == "Other"){
            let images: Array<Dictionary<String,Any>> = self.allImages.filter { (item) -> Bool in
                let a:String  = item["folder"] as? String ?? ""
                return a == "All"
            }
            result(images)
        }else{
            let images: Array<Dictionary<String,Any>> = self.allImages.filter { (item) -> Bool in
                let a:String  = item["folder"] as? String ?? ""
                return a.contains(folder)
            }
            result(images)
        }
    }
    
    //Mark:获取文件名
    private func getName(path:String)->String{
        var name = ""
        if(path.contains("/")){
            name = "\(path.split(separator: "/").last ?? "")"
        }else{
            name = path
        }
         print(name)
        return name
    }
    
    private func getPath(asset:PHAsset,folder:String)->Dictionary<String,Any>{
        var d : Dictionary<String,Any>
        if(asset.mediaType == PHAssetMediaType.image){
            d =  getImagePath(asset: asset)
        }else{
            d = getVideoPath(asset: asset)
        }
        d.updateValue(folder, forKey: "folder")
        return d
    }
    //MARK:获取图片绝对路径
    private func getImagePath(asset:PHAsset)->Dictionary<String,Any>{
        var path:String = ""
        let semaphore = DispatchSemaphore(value: 0)
        let options2 = PHContentEditingInputRequestOptions()
        options2.isNetworkAccessAllowed = true
        asset.requestContentEditingInput(with: options2){(input, info) in
            path = input?.fullSizeImageURL?.path ?? ""
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        var d = Dictionary<String,Any>();
        d.updateValue(asset.localIdentifier, forKey: "id")
        let name = self.getName(path: path)
    
        d.updateValue(path, forKey: "path")
        d.updateValue(name, forKey: "name")
        d.updateValue("image/",forKey: "mimeType");
        d.updateValue(Int(asset.creationDate!.timeIntervalSince1970),forKey: "time");
        d.updateValue(asset.pixelWidth,forKey: "width");
        d.updateValue(asset.pixelHeight, forKey: "height");
        return d
    }
    //MARK:获取视频绝对路径
    private func getVideoPath(asset:PHAsset)->Dictionary<String,Any>{
        var path:String = ""
        let semaphore = DispatchSemaphore(value: 0)
        manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: {(asset,v,any) in
            let  url = (asset as? AVURLAsset)?.url.absoluteString
            path = url?.replacingOccurrences(of: "file://", with: "") ?? "";
            semaphore.signal()
        });
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        var d = Dictionary<String,Any>();
        d.updateValue(asset.localIdentifier, forKey: "id")
        let name = self.getName(path: path)
        d.updateValue(path, forKey: "path")
        d.updateValue(name, forKey: "name")
        d.updateValue("video/",forKey: "mimeType");
        d.updateValue(Int(asset.creationDate!.timeIntervalSince1970),forKey: "time");
        d.updateValue(asset.pixelWidth,forKey: "width");
        d.updateValue(asset.pixelHeight, forKey: "height");
        return d
    }
    
    //MARK：FLutter不支持图片视频缩略图获取方式
    private func toUInt8List(id:String,width:Int,height:Int,result:@escaping FlutterResult){
        DispatchQueue.global(qos: .default).async {
            var data:Data?
            let semaphore = DispatchSemaphore(value: 0)
            let  asset:PHAsset? = PHAsset.fetchAssets(withLocalIdentifiers: [id],options: nil).firstObject;
            if(asset != nil){
                self.manager.requestImage(for: asset!, targetSize: CGSize(width: width, height: height), contentMode: .aspectFit, options: nil, resultHandler: {(image,any) in
                    data = image?.jpegData(compressionQuality: 75) ?? nil
                    semaphore.signal()
                });
            }else{
                semaphore.signal()
            }
             _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            DispatchQueue.main.async{
                result(data)
            }
        }
    }
    
    //MARK：任务取消
    private func cancelAll(result:@escaping FlutterResult){
        manager.stopCachingImagesForAllAssets();
        result(true);
    }
    
    //MARK：拍照录制视频回调
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[.mediaType] as! String;
        if(mediaType.contains("image")){
            let image:UIImage?  = info[.originalImage] as? UIImage;
            if(image != nil){
                self.takePhotoData(image: image!, done: {
                    picker.dismiss(animated: true, completion: nil);
                })
            }else{
                picker.dismiss(animated: true, completion: nil);
            }
        }else if(mediaType.contains("movie")){
            let videoUrl:NSURL? = info[.mediaURL] as? NSURL;
            if(videoUrl != nil){
                self.takeVideoData(videoUrl: videoUrl!, done: {
                    picker.dismiss(animated: true, completion: nil);
                })
            }else{
                picker.dismiss(animated: true, completion: nil);
            }
        }else{
            picker.dismiss(animated: true, completion: nil);
        }
        
    }
    
    // MARK: 录制视频获取
    private func takeVideoData(videoUrl:NSURL,done: @escaping @convention(block) () -> Void){
        DispatchQueue.global(qos: .default).async {
            let semaphore = DispatchSemaphore(value: 0)
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl.absoluteURL!)
            }, completionHandler: {isSuccess, e in
                if(isSuccess){
                    let a = PHAsset.fetchAssets(with: .image, options: nil).lastObject;
                    if(a != nil){
                        let a = self.getVideoPath(asset: a!)
                        self.result?(a);
                        self.result = nil;
                        semaphore.signal()
                    }else{
                        semaphore.signal()
                    }
                }else{
                    semaphore.signal()
                }
                 _ = semaphore.wait(timeout: DispatchTime.distantFuture)
                done()
            });
        }
    }
    
    // MARK: 拍照照片获取
    private func takePhotoData(image:UIImage,done: @escaping @convention(block) () -> Void){
        DispatchQueue.global(qos: .default).async {
            let semaphore = DispatchSemaphore(value: 0)
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from:image);
            }, completionHandler: {isSuccess, e in
                if(isSuccess){
                    let a = PHAsset.fetchAssets(with: .image, options: nil).lastObject;
                    if(a != nil){
                        let a = self.getImagePath(asset: a!)
                        self.result?(a);
                        self.result = nil;
                        semaphore.signal()
                    }else{
                        semaphore.signal()
                    }
                }else{
                    semaphore.signal()
                }
                 _ = semaphore.wait(timeout: DispatchTime.distantFuture)
                done()
            });
        }
    }
    
    // MARK: 拍照与录制视频
    private func takePicker(isVideo:Bool,result:@escaping FlutterResult){
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
