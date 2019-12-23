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
    var works = Array<DispatchWorkItem>()
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
        }else if(call.method == "getPath"){
            getPath(id: call.arguments as!String, result: result)
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
        let old = Date().timeIntervalSince1970
        allImages.removeAll()
        allFolders.removeAll()
        allFolders.append("All")
        let work =  DispatchWorkItem {
            let fetchOptions = PHFetchOptions()
            if(type == 1){
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            }else if(type == 2 ){
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            }else{}
            let all = PHAsset.fetchAssets(with: fetchOptions);

            //self.awaitAllPath(all: all) 该方法耗时太久
            //资源绝对路径改为flutter图片显示异步加载，见方法@see getPath(id:String,result:@escaping FlutterResult)
            for index in 0..<all.count{
                let asset = all[index]
                var d = Dictionary<String,Any>();
                d.updateValue(asset.localIdentifier, forKey: "id")
                d.updateValue("", forKey: "path")
                d.updateValue("", forKey: "name")
                if(asset.mediaType == PHAssetMediaType.image){
                    d.updateValue("image/",forKey: "mimeType");
                }else{
                    d.updateValue("video/",forKey: "mimeType");
                }
                d.updateValue(Int(asset.creationDate!.timeIntervalSince1970),forKey: "time");
                d.updateValue(asset.pixelWidth,forKey: "width");
                d.updateValue(asset.pixelHeight, forKey: "height");
                d.updateValue("All", forKey: "folder")
                self.allImages.append(d);
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
            let cur = Date().timeIntervalSince1970
            logE("全部结束")
            logE("\(cur - old)")
            DispatchQueue.main.async {
               result(self.allFolders)
            }
        }
        self.works.append(work)
        DispatchQueue.global(qos: .background).async(execute: work)
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
        logE(name)
        return name
    }
    //MARK：获取所用图片的路径、并且异步任务同时完成返回，一次性获取等待时间太久，该方法废弃
    private func awaitAllPath(all:PHFetchResult<PHAsset>){
        let old = Date().timeIntervalSince1970
        let queue = DispatchQueue.global()
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 16)
        for index in 0..<all.count{
            group.enter()
            semaphore.wait()
            queue.async(group: group, execute: {
                let a = all[index];
                self.getPath(asset: a, folder: "All",result: {d in
                    self.allImages.append(d);
                    semaphore.signal()
                    group.leave()
                })
            })
        }
        _ = group.wait(wallTimeout: DispatchWallTime.distantFuture)
        logE("结束")
        let cur = Date().timeIntervalSince1970
        logE("\(cur - old)")
    }
    //MARK：通过PHAsset获取图片文件绝对路径
    private func getPath(asset:PHAsset,folder:String,result:@escaping(Dictionary<String,Any>)->Void){
        if(asset.mediaType == PHAssetMediaType.image){
            getImagePath(asset: asset,folder: folder,result: result)
        }else{
            getVideoPath(asset: asset,folder: folder,result: result)
        }
    }

    //MARK：通过LocalIdentifiers获取图片文件绝对路径
    private func getPath(id:String,result:@escaping FlutterResult){
        let work = DispatchWorkItem {
            var path:String = ""
            let  asset:PHAsset? = PHAsset.fetchAssets(withLocalIdentifiers: [id],options: nil).firstObject;
            if(asset != nil){
                self.getPath(asset: asset!, folder: "") { (d) in
                    path = d["path"] as! String
                    DispatchQueue.main.async{
                        result(path)
                    }
                }
            }else{
                DispatchQueue.main.async{
                    result(path)
                }
            }
        }
        self.works.append(work)
        DispatchQueue.global(qos: .background).async(execute: work)
    }
    //MARK:获取图片绝对路径
    private func getImagePath(asset:PHAsset,folder:String,result:@escaping(Dictionary<String,Any>)->Void){
        let options2 = PHContentEditingInputRequestOptions()
        options2.isNetworkAccessAllowed = true
        asset.requestContentEditingInput(with: options2){input, info in
            let path:String = input?.fullSizeImageURL?.path ?? ""
            var d = Dictionary<String,Any>();
            d.updateValue(asset.localIdentifier, forKey: "id")
            let name = self.getName(path: path)
            d.updateValue(path, forKey: "path")
            d.updateValue(name, forKey: "name")
            d.updateValue("image/",forKey: "mimeType");
            d.updateValue(Int(asset.creationDate!.timeIntervalSince1970),forKey: "time");
            d.updateValue(asset.pixelWidth,forKey: "width");
            d.updateValue(asset.pixelHeight, forKey: "height");
            d.updateValue(folder, forKey: "folder")
            result(d)
        }
    }
    //MARK:获取视频绝对路径
    private func getVideoPath(asset:PHAsset,folder:String, result:@escaping(Dictionary<String,Any>)->Void){
        self.manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: {a,v,any in
            let  url = (a as? AVURLAsset)?.url.absoluteString
            let path = url?.replacingOccurrences(of: "file://", with: "") ?? "";
            var d = Dictionary<String,Any>();
            d.updateValue(asset.localIdentifier, forKey: "id")
            let name = self.getName(path: path)
            d.updateValue(path, forKey: "path")
            d.updateValue(name, forKey: "name")
            d.updateValue("video/",forKey: "mimeType");
            d.updateValue(Int(asset.creationDate!.timeIntervalSince1970),forKey: "time");
            d.updateValue(asset.pixelWidth,forKey: "width");
            d.updateValue(asset.pixelHeight, forKey: "height");
            d.updateValue(folder, forKey: "folder")
            result(d)
        });
    }

    //MARK：FLutter不支持图片视频缩略图获取方式
    private func toUInt8List(id:String,width:Int,height:Int,result:@escaping FlutterResult){
        DispatchQueue.global(qos: .background).async {
            var data:Data?
            let  asset:PHAsset? = PHAsset.fetchAssets(withLocalIdentifiers: [id],options: nil).firstObject;
            if(asset != nil){
                self.manager.requestImage(for: asset!, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil, resultHandler: {(image,any) in
                    data = image?.jpegData(compressionQuality: 100) ?? nil
                    DispatchQueue.main.async{
                        result(data)
                    }
                });
            }else{
                DispatchQueue.main.async{
                    result(data)
                }
            }
        }
    }

    //MARK：任务取消
    private func cancelAll(result:@escaping FlutterResult){
        manager.stopCachingImagesForAllAssets();
        for work in self.works {
            if(!work.isCancelled){
                work.cancel()
            }
        }
        self.works.removeAll()
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
        self.createAndGetAlbum { (album) in
            PHPhotoLibrary.shared().performChanges({
                if album == nil {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl.absoluteURL!)
                }else{
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl.absoluteURL!)
                    let assetPlaceholder = assetRequest?.placeholderForCreatedAsset!
                    _=PHAssetCollectionChangeRequest.init(for: album!)?.addAssets([assetPlaceholder!] as NSArray)
                }
            }, completionHandler: {success, e in
                if(success){
                    let a = PHAsset.fetchAssets(with: .video, options: nil).lastObject;
                    if(a != nil){
                        self.getVideoPath(asset: a!,folder: "",result: {a in
                            self.result?(a);
                            self.result = nil;
                            done()
                        })
                    }else{
                       done()
                    }
                }else{
                   done()
                }
            });
        }
    }

    // MARK: 拍照照片获取
    private func takePhotoData(image:UIImage,done: @escaping @convention(block) () -> Void){
        self.createAndGetAlbum { (album) in
            PHPhotoLibrary.shared().performChanges({
                if album == nil {
                    PHAssetChangeRequest.creationRequestForAsset(from:image);
                }else{
                    let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let assetPlaceholder = assetRequest.placeholderForCreatedAsset!
                    _=PHAssetCollectionChangeRequest.init(for: album!)?.addAssets([assetPlaceholder] as NSArray)
                }
            }, completionHandler: {success, e in
                if(success){
                    let a = PHAsset.fetchAssets(with: .image, options: nil).lastObject;
                    if(a != nil){
                        self.getImagePath(asset: a!,folder: "",result: {a in
                            self.result?(a);
                            self.result = nil;
                            done()
                        })
                    }else{
                        done()
                    }
                }else{
                    done()
                }
            });
        }
    }
    func createAndGetAlbum(_ done: @escaping @convention(block) (PHAssetCollection?) -> Void){
        let albumName = "image_picker_flutter"
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate.init(format: "title = %@", albumName)
        var albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let _ = albums.firstObject {
            done(albums.firstObject)
        }else{
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }) { (result, error) in
                albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                done(albums.firstObject)
            }
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
            logE("camera is nil");
        }
    }
}
