package com.mycompany.mobilesecv2

/*import android.accessibilityservice.AccessibilityServiceInfo  // <-- Added import
import android.view.accessibility.AccessibilityManager */
import android.app.AlertDialog
import android.content.DialogInterface
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.mycompany.mobilesecv2/keylogger"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKeyLogger" -> {
                    Log.d("KeyLogger", "Keylogger started.")
                    result.success("Keylogger is active")
                }
                else -> result.notImplemented()
            }
        }
    }
    /*
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Get AccessibilityManager instance
        val accessibilityManager = getSystemService(AccessibilityManager::class.java)
        val isEnabled = isAccessibilityServiceEnabled(accessibilityManager)

        if (!isEnabled) {
            // Show dialog to enable the service
            AlertDialog.Builder(this)
                .setTitle("Enable Accessibility Service")
                .setMessage("Please enable the service to log keystrokes.")
                .setPositiveButton("Go to Settings") { dialog: DialogInterface, which: Int ->
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                }
                .setNegativeButton("Cancel") { dialog: DialogInterface, which: Int ->
                    dialog.dismiss()
                    finish()
                }
                .show()
        }
    }

    private fun isAccessibilityServiceEnabled(accessibilityManager: AccessibilityManager): Boolean {
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_GENERIC  // <-- Updated constant reference
        )
        return enabledServices.any { serviceInfo ->
            serviceInfo.resolveInfo.serviceInfo.name == KeyLoggerAccessibilityService::class.java.name
        }
    }
    */

}
