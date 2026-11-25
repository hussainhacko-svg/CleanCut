package com.hussainhacko.cleancut

import android.content.Intent
import com.hussainhacko.cleancut.media.MediaPicker
import com.hussainhacko.cleancut.media.MediaPickerHostApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var mediaPicker: MediaPicker? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val picker = MediaPicker(this)
        mediaPicker = picker
        MediaPickerHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, picker)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MediaPickerHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        mediaPicker?.dispose()
        mediaPicker = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("FlutterActivity has no ActivityResult registry")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (mediaPicker?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
