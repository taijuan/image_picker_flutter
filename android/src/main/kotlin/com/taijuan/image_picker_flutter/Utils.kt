package com.taijuan.image_picker_flutter

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

/**
 * 默认情况下，即不需要指定intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
 * 照相机有自己默认的存储路径，拍摄的照片将返回一个缩略图。如果想访问原始图片，
 * 可以通过dat extra能够得到原始图片位置。即，如果指定了目标uri，data就没有数据，
 * 如果没有指定uri，则data就返回有数据！
 *
 * 7.0 调用系统相机拍照不再允许使用Uri方式，应该替换为FileProvider
 */
internal fun PluginRegistry.Registrar.takePicture(result: MethodChannel.Result) {

    var takeImageFile = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
    } else {
        context().getExternalFilesDir(Environment.DIRECTORY_DCIM)
    } ?: context().filesDir
    takeImageFile = createFile(takeImageFile, "IMG-", ".jpg")
    val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
    takePictureIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
    if (takePictureIntent.resolveActivity(activity().packageManager) != null) {
        val uri = if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.M) {
            Uri.fromFile(takeImageFile)
        } else {
            takePictureIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            FileProvider.getUriForFile(activity(), "${activity().packageName}.provider", takeImageFile)
        }
        takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, uri)
        activity().startActivityForResult(takePictureIntent, REQUEST_CAMERA_IMAGE)

        resultListener.onCompleted = {
            MediaScannerConnection.scanFile(context().applicationContext, arrayOf(takeImageFile.toString()), arrayOf("image/*")) { path, _ ->
                path.logcat()
                if (path == takeImageFile.toString()) {
                    val imageItem = HashMap<String, Any>().apply {
                        put("id", path)
                        put("name", takeImageFile.name)
                        put("path", path)
                        put("mimeType", "image/jpg")
                        put("time", System.currentTimeMillis())
                        val arr = size(path)
                        Log.e("zuiweng", arr.toString())
                        put("width", arr[0])
                        put("height", arr[1])
                    }

                    this.activity().runOnUiThread {
                        result.success(imageItem)
                    }
                }

            }
        }
    }
}

/**
 * 默认情况下，即不需要指定intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
 * 照相机有自己默认的存储路径，拍摄的照片将返回一个缩略图。如果想访问原始图片，
 * 可以通过dat extra能够得到原始图片位置。即，如果指定了目标uri，data就没有数据，
 * 如果没有指定uri，则data就返回有数据！
 *
 * 7.0 调用系统相机拍照不再允许使用Uri方式，应该替换为FileProvider
 */
internal fun PluginRegistry.Registrar.takeVideo(result: MethodChannel.Result) {
    var takeImageFile = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
    } else {
        context().getExternalFilesDir(Environment.DIRECTORY_MOVIES)
    } ?: context().filesDir
    takeImageFile = createFile(takeImageFile, "VIDEO-", ".mp4")
    val takePictureIntent = Intent(MediaStore.ACTION_VIDEO_CAPTURE)
    takePictureIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
    if (takePictureIntent.resolveActivity(activity().packageManager) != null) {
        val uri = if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.M) {
            Uri.fromFile(takeImageFile)
        } else {
            takePictureIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            FileProvider.getUriForFile(activity(), "${activity().packageName}.provider", takeImageFile)
        }
        takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, uri)
        activity().startActivityForResult(takePictureIntent, REQUEST_CAMERA_VIDEO)
    }
    resultListener.onCompleted = {
        MediaScannerConnection.scanFile(context().applicationContext, arrayOf(takeImageFile.toString()), arrayOf("video/*")) { path, _ ->
            if (path == takeImageFile.toString()) {
                val imageItem = HashMap<String, Any>().apply {
                    put("id", path)
                    put("name", takeImageFile.name)
                    put("path", path)
                    put("mimeType", "video/mp4")
                    put("time", System.currentTimeMillis())
                    val arr = size(path, isImage = false)
                    put("width", arr[0])
                    put("height", arr[1])
                }
                this.activity().runOnUiThread {
                    result.success(imageItem)
                }
            }
        }
    }
}

/**
 * 根据系统时间、前缀、后缀产生一个文件
 */
private fun createFile(folder: File, prefix: String, suffix: String): File {
    if (!folder.exists() || !folder.isDirectory) folder.mkdirs()
    val dateFormat = SimpleDateFormat("yyyy-MM-dd-HH-mm-ss", Locale.getDefault())
    val filename = prefix + dateFormat.format(Date(System.currentTimeMillis())) + suffix
    return File(folder, filename)
}

private const val REQUEST_CAMERA_IMAGE = 0x23
private const val REQUEST_CAMERA_VIDEO = 0x24

internal val resultListener: ResultListener = ResultListener()

internal fun PluginRegistry.Registrar.addActivityResultListener() {
    this.addActivityResultListener(resultListener)
}

internal class ResultListener : PluginRegistry.ActivityResultListener {
    internal var onCompleted: (() -> Unit)? = null
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CAMERA_IMAGE && requestCode != REQUEST_CAMERA_VIDEO) return true
        if (resultCode != Activity.RESULT_OK) return true
        onCompleted?.invoke()
        return true
    }

}

internal fun size(path: String, isImage: Boolean = true): Array<Int> {
    return if (isImage) {
        val bitmap = BitmapFactory.decodeFile(path)
        arrayOf(bitmap.width, bitmap.height)
    } else {
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(path)
        val bitmap = retriever.frameAtTime
        arrayOf(bitmap.width, bitmap.height)
    }
}

internal fun Any.logcat() {
    Log.e("image_picker", this.toString())
}
