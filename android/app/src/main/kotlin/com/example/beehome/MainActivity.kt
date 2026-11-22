package com.example.beehome

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var selection: MethodChannel.Result? = null
    private val photoRequest = 4917

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beehome/photo").setMethodCallHandler { call, result ->
            if (call.method != "choose") { result.notImplemented(); return@setMethodCallHandler }
            if (selection != null) { result.error("busy", "Đang chọn ảnh.", null); return@setMethodCallHandler }
            selection = result
            try {
                startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "image/*"
                }, photoRequest)
            } catch (e: Exception) { selection = null; result.error("unavailable", "Chưa mở được thư viện ảnh.", null) }
        }
    }

    @Deprecated("Activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != photoRequest) return
        val result = selection ?: return
        selection = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { result.success(null); return }
        Thread {
            try {
                val bytes = contentResolver.openInputStream(uri)!!.use { input ->
                    val out = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    var size = input.read(buffer)
                    while (size != -1) {
                        require(out.size() + size <= 8 * 1024 * 1024)
                        out.write(buffer, 0, size)
                        size = input.read(buffer)
                    }
                    out.toByteArray()
                }
                runOnUiThread { result.success(bytes) }
            } catch (e: Exception) { runOnUiThread { result.error("invalid-photo", "Chọn ảnh đọc được dưới 8 MB.", null) } }
        }.start()
    }
}
