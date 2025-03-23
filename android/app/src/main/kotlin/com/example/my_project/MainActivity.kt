package com.mycompany.mobilesecv2

import android.util.Log
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    // Must match the MethodChannel name used in main.dart
    private val CHANNEL = "com.mycompany.mobilesecv2/keylogger"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up a MethodChannel to handle calls from Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "startKeyLogger" -> {
                    // Do any initialization for keylogging if needed
                    Log.d("KeyLogger", "Keylogger started.")
                    result.success("Keylogger is active")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Override dispatchKeyEvent to capture hardware key events
    override fun dispatchKeyEvent(event: KeyEvent?): Boolean {
        event?.let {
            if (it.action == KeyEvent.ACTION_DOWN) {
                // Log the keycode. Check Logcat for the output.
                Log.d("KeyLogger", "Key pressed: ${it.keyCode}")
            }
        }
        return super.dispatchKeyEvent(event)
    }
}
