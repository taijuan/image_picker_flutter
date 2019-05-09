package com.taijuan.image_picker_flutter

import android.annotation.SuppressLint
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

@Suppress("UNCHECKED_CAST")
class ImagePickerFlutterPlugin : MethodCallHandler {
    companion object {

        @SuppressLint("StaticFieldLeak")
        private lateinit var registrar: Registrar

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            this.registrar = registrar
            val channel = MethodChannel(registrar.messenger(), "image_picker")
            channel.setMethodCallHandler(ImagePickerFlutterPlugin())
            registrar.addActivityResultListener()
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when {
            call.method == "getImages" -> registrar.activity().loadInBackground(when (call.arguments as Int) {
                1 -> IMAGE_SELECTION
                2 -> VIDEO_SELECTION
                else -> "$IMAGE_SELECTION or $VIDEO_SELECTION"
            }, result)
            call.method == "toUInt8List" -> registrar.activity().loadInBackgroundToUInt8List(call.arguments as List<Any>, result)
            call.method == "cancelAll" -> cancelBackground(result)
            call.method == "takePicture" -> registrar.takePicture(result)
            call.method == "takeVideo" -> registrar.takeVideo(result)
            else -> result.notImplemented()
        }
    }
}
