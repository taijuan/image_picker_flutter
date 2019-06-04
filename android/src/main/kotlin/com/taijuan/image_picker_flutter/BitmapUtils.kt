package com.taijuan.image_picker_flutter

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream

fun Bitmap.compress(minWidth: Int, minHeight: Int): ByteArray {
    val bos = ByteArrayOutputStream()
    val w = this.width
    val h = this.height
    val scaleW = w / minWidth
    val scaleH = h / minHeight
    val scale = Math.max(1, Math.max(scaleW, scaleH))
    val destW = w / scale
    val destH = h / scale
    Bitmap.createScaledBitmap(this, destW, destH, true)
            .compress(Bitmap.CompressFormat.JPEG, 100, bos)
    return bos.toByteArray()
}
