package com.taijuan.image_picker_flutter

import android.annotation.SuppressLint
import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

@Suppress("UNCHECKED_CAST")
class ImagePickerFlutterPlugin: MethodCallHandler {
  companion object {

    @SuppressLint("StaticFieldLeak")
    private lateinit var context: Context

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "image_picker")
      channel.setMethodCallHandler(ImagePickerFlutterPlugin())
      context = registrar.context().applicationContext
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when {
      call.method == "getImages" -> context.loadInBackground(when (call.arguments as Int) {
        1 -> IMAGE_SELECTION
        2 -> VIDEO_SELECTION
        else -> "$IMAGE_SELECTION or $VIDEO_SELECTION"
      }, result)
      call.method == "toUInt8List" -> loadInBackgroundToUInt8List(call.arguments as List<Any>, result)
      call.method == "cancelAll" -> {
        cancelBackground()
        result.success(true)
      }
      else -> result.notImplemented()
    }
  }
}
