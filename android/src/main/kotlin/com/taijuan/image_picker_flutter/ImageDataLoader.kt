/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.taijuan.image_picker_flutter

import android.app.Activity
import android.database.Cursor
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.ScheduledExecutorService


private val IMAGE_PROJECTION = arrayOf(//查询图片需要的数据列
        MediaStore.MediaColumns.DISPLAY_NAME, //图片的显示名称  aaa.jpg
        MediaStore.MediaColumns.DATA, //图片的真实路径  /storage/emulated/0/pp/downloader/wallpaper/aaa.jpg
        MediaStore.MediaColumns.MIME_TYPE, //图片的类型     image/jpeg
        MediaStore.MediaColumns.DATE_ADDED,
        MediaStore.MediaColumns.WIDTH,
        MediaStore.MediaColumns.HEIGHT)    //图片被添加的时间，long型  1450518608

internal const val IMAGE_SELECTION = "${MediaStore.Files.FileColumns.MEDIA_TYPE}=${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} AND ${MediaStore.Files.FileColumns.SIZE}>0"
internal const val VIDEO_SELECTION = "${MediaStore.Files.FileColumns.MEDIA_TYPE}=${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO} AND ${MediaStore.Files.FileColumns.SIZE}>0"


internal fun Activity.loadInBackground(selection: String, result: MethodChannel.Result) {
    "start loadInBackground".logcat()
    val data = arrayListOf<HashMap<String, Any>>()
    runBackground {
        var cursor: Cursor? = null
        try {
            cursor = MediaStore.Images.Media.query(this.contentResolver,
                    MediaStore.Files.getContentUri("external"),
                    arrayOf(MediaStore.MediaColumns.DISPLAY_NAME, //图片的显示名称  aaa.jpg
                            MediaStore.MediaColumns.DATA, //图片的真实路径  /storage/emulated/0/pp/downloader/wallpaper/aaa.jpg
                            MediaStore.MediaColumns.MIME_TYPE, //图片的类型     image/jpeg
                            MediaStore.MediaColumns.DATE_ADDED,
                            MediaStore.MediaColumns.WIDTH,
                            MediaStore.MediaColumns.HEIGHT),
                    selection, arrayOf(),
                    IMAGE_PROJECTION[3] + " DESC")
            if (cursor != null) {
                while (cursor.moveToNext()) {
                    val name = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME))
                    val path = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA))
                    val imageFile = File(path)
                    if (!imageFile.exists() || imageFile.length() <= 0) {
                        continue
                    }
                    val mimeType = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE))
                    val time = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED))
                    val width = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.WIDTH))
                    val height = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.HEIGHT))
                    val imageItem = HashMap<String, Any>().apply {
                        put("id", path)
                        put("name", name)
                        put("path", path)
                        put("mimeType", mimeType)
                        put("time", time)
                        put("width", width)
                        put("height", height)
                    }
                    data.add(imageItem)
                }
            }
        } catch (e: Exception) {
            e.logcat()
        } finally {
            cursor?.close()
            "end loadInBackground".logcat()
            runOnUiThread {
                result.success(data)
            }
        }
    }
}


internal fun Activity.loadInBackgroundToUInt8List(res: List<Any>, result: MethodChannel.Result) {
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
