package com.hussainhacko.cleancut

import android.content.Intent
import com.hussainhacko.cleancut.engine.EngineFlutterApi
import com.hussainhacko.cleancut.engine.EngineHost
import com.hussainhacko.cleancut.engine.EngineHostApi
import com.hussainhacko.cleancut.media.MediaPicker
import com.hussainhacko.cleancut.media.MediaPickerHostApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var mediaPicker: MediaPicker? = null
    private var engine: EngineHost? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val picker = MediaPicker(this)
        mediaPicker = picker
        MediaPickerHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, picker)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val host = EngineHost(applicationContext, flutterEngine.renderer, EngineFlutterApi(messenger))
        engine = host
        EngineHostApi.setUp(messenger, host)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MediaPickerHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        EngineHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        engine?.dispose()
        engine = null
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
