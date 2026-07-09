package com.gigbook.gigbook

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Writes bytes directly to an already-known SAF document URI via
 * ContentResolver, truncating first ("wt" mode). Used instead of
 * saf_stream's writeFileBytes(overwrite: true), which locates the target
 * file by matching its display name via DocumentFile.findFile() — a linear
 * listing lookup that's unreliable against Google Drive's SAF provider and
 * can silently create a duplicate file instead of overwriting the original.
 * Addressing the file by its own URI (which GigBook already has on hand for
 * every linked song) sidesteps that lookup entirely.
 */
private const val SAF_WRITE_CHANNEL = "com.gigbook.gigbook/saf_write"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SAF_WRITE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "writeToUri") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val uri = call.argument<String>("uri")!!
                    val bytes = call.argument<ByteArray>("bytes")!!
                    val outputStream = contentResolver.openOutputStream(Uri.parse(uri), "wt")
                        ?: throw Exception("Could not open output stream for $uri")
                    outputStream.use { it.write(bytes) }
                    result.success(null)
                } catch (e: Exception) {
                    result.error("WRITE_FAILED", e.message, null)
                }
            }
    }
}
