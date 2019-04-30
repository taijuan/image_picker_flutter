package com.taijuan.image_picker_flutter

import androidx.core.content.FileProvider

/**
 * 自定义一个Provider，以免和引入的项目的provider冲突
 *
 */
class ImagePickerProvider : FileProvider()
