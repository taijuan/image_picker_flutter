package com.taijuan.image_picker_flutter

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream

fun Bitmap.compress(minWidth: Int, minHeight: Int): ByteArray {
    val bos = ByteArrayOutputStream()
    val w = this.width
    val h = this.height
    val scaleW: Float = w * 1f / minWidth
    val scaleH: Float = h * 1f / minHeight
    val scale = 1f.coerceAtLeast(scaleW.coerceAtLeast(scaleH))
    val destW = w / scale
    val destH = h / scale
    Bitmap.createScaledBitmap(this, destW.toInt(), destH.toInt(), true)
            .compress(Bitmap.CompressFormat.JPEG, 100, bos)
    return bos.toByteArray()
}
