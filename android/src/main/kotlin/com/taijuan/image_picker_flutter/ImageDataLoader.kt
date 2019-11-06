package com.taijuan.image_picker_flutter

import android.app.Activity
import android.content.ContentUris
import android.database.Cursor
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.ScheduledExecutorService


private val IMAGE_PROJECTION = arrayOf(//查询图片需要的数据列
        MediaStore.Files.FileColumns._ID,
        MediaStore.MediaColumns.DISPLAY_NAME, //图片的真实路径  /storage/emulated/0/pp/downloader/wallpaper/aaa.jpg
        MediaStore.MediaColumns.MIME_TYPE, //图片的类型     image/jpeg
        MediaStore.MediaColumns.DATE_ADDED,
        MediaStore.MediaColumns.WIDTH,
        MediaStore.MediaColumns.HEIGHT)    //图片被添加的时间，long型  1450518608

internal const val IMAGE_SELECTION = "${MediaStore.Files.FileColumns.MEDIA_TYPE}=${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} AND ${MediaStore.Files.FileColumns.SIZE}>0"
internal const val VIDEO_SELECTION = "${MediaStore.Files.FileColumns.MEDIA_TYPE}=${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO} AND ${MediaStore.Files.FileColumns.SIZE}>0"

internal val allImages = arrayListOf<HashMap<String, Any>>()
internal val allFolders = arrayListOf<String>()
internal fun Activity.getFolders(selection: String, result: MethodChannel.Result) {
    allImages.clear()
    allFolders.clear()
    allFolders.add("/All")
    runBackground {
        var cursor: Cursor? = null
        try {
            cursor = this.contentResolver.query(MediaStore.Files.getContentUri("external"), IMAGE_PROJECTION, selection, arrayOf(), IMAGE_PROJECTION[3] + " DESC")
            if (cursor != null) {
                while (cursor.moveToNext()) {
                    val name = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME))
                    val path = PathUtils.getPath(this, cursor.getUri())
                    val imageFile = File(path)
                    if (!imageFile.exists() || imageFile.length() <= 0) {
                        continue
                    }
                    val folder = imageFile.parentFile?.absolutePath ?: "/All"
                    if (!allFolders.contains(folder)) {
                        allFolders.add(folder)
                    }
                    val mimeType = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE))
                    /**
                     * @see：MediaStore.MediaColumns.DATE_ADDED 单位秒
                     */
                    val time = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED))*1000
                    val width = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH))
                    val height = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT))
                    val imageItem = HashMap<String, Any>().apply {
                        put("id", path)
                        put("name", name)
                        put("path", path)
                        put("folder", folder)
                        put("mimeType", mimeType)
                        put("time", time)
                        put("width", width)
                        put("height", height)
                    }
                    allImages.add(imageItem)
                }
                createFolder().listFiles()?.filter {
                    when (selection) {
                        IMAGE_SELECTION -> it.name.contains(".jpg")
                        VIDEO_SELECTION -> it.name.contains(".mp4")
                        else -> true
                    }
                }?.forEach {
                    val folder = it.parentFile?.absolutePath ?: "/All"
                    if (!allFolders.contains(folder)) {
                        allFolders.add(folder)
                    }
                    val imageItem = HashMap<String, Any>().apply {
                        put("id", it.absolutePath)
                        put("name", it.name)
                        put("path", it.absolutePath)
                        put("folder", folder)
                        val isImage = it.name.contains(".jpg")
                        put("mimeType", if (isImage) "image/jpg" else "video/mp4")
                        put("time", it.lastModified())
                        val arr = size(it.absolutePath, isImage = isImage)
                        arr.logE()
                        put("width", arr[0])
                        put("height", arr[1])
                    }
                    allImages.add(imageItem)
                }
            }
        } catch (e: Exception) {
            e.logT()
        } finally {
            cursor?.close()
            runOnUiThread {
                allFolders.logE()
                result.success(allFolders)
            }
        }
    }
}

internal fun Activity.getImages(folder: String, result: MethodChannel.Result) {
    if (folder == "/All") {
        runOnUiThread {
            result.success(allImages)
        }
    } else {
        val images = arrayListOf<HashMap<String, Any>>()
        allImages.forEach {
            if (it["folder"] == folder) {
                images.add(it)
            }
        }
        runOnUiThread {
            result.success(images)
        }
    }
}

internal fun Activity.toUInt8List(res: List<Any>, result: MethodChannel.Result) {
//    data.clear()
    runBackground {
        try {
            val path = res[0] as String
            val isImage = res[1] as Boolean
            val width = res[2] as Int
            val height = res[3] as Int
            if (isImage) {
                val bytes = BitmapFactory.decodeFile(path).compress(width, height)
                runOnUiThread {
                    result.success(bytes)
                }
            } else {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(path)
                val bytes = retriever.frameAtTime.compress(width, height)
                runOnUiThread {
                    result.success(bytes)
                }
            }
        } catch (e: Exception) {
            runOnUiThread {
                result.success(null)
            }
        }
    }
}

private class BackgroundTask {
    lateinit var future: Future<*>
}

private val background: ScheduledExecutorService by lazy { Executors.newScheduledThreadPool(Runtime.getRuntime().availableProcessors()) }
private val backgroundMap: MutableList<BackgroundTask> by lazy {
    mutableListOf<BackgroundTask>()
}

private fun runBackground(body: () -> Unit) {
    val task = BackgroundTask()
    backgroundMap.add(task)
    task.future = background.submit {
        body.invoke()
        backgroundMap.remove(task)
    }

}

internal fun cancelBackground(result: MethodChannel.Result) {
    backgroundMap.filter { !it.future.isDone }.map { it.future.cancel(true) }
    backgroundMap.clear()
    result.success(true)
}

private fun Cursor.getUri(): Uri {
    val id = this.getLong(this.getColumnIndex(MediaStore.Files.FileColumns._ID))
    val mimeType = this.getString(this.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE))
    val contentUri = when {
        mimeType.contains("image") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        mimeType.contains("video") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        else -> MediaStore.Files.getContentUri("external")
    }
    return ContentUris.withAppendedId(contentUri, id)
}
