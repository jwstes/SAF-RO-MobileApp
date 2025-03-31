import 'dart:async';
import 'dart:convert';
// Remove latlong2 import if not used elsewhere, geolocator provides Lat/Lng via Position
// import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/services.dart'; // For MethodChannel
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler; // Use alias to avoid conflict if needed

// ===>>> Define the channel to send updates TO native code <<<===
const MethodChannel _nativeLocationUpdateChannel = MethodChannel('com.mycompany.mobilesecv2/location_update');
// ============================================================


// Helper function to get location using Geolocator
// Added return type Position? to handle potential errors gracefully
Future<Position?> getCurrentUserLocationInternal() async {
  // 1. Check Service Enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (kDebugMode) print("Location service disabled. Trying to open settings...");
    // Optionally open settings, but don't block here indefinitely in background service.
    // await Geolocator.openLocationSettings();
    // Consider returning null or throwing an error if service is required immediately.
    return null;
  }

  // 2. Check Permission (redundant if requestLocationPermissions is called first, but good practice)
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    if (kDebugMode) print("Location permission denied. Requesting...");
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (kDebugMode) print("Location permission denied (or permanently denied).");
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
     if (kDebugMode) print("Location permission permanently denied.");
    return null;
  }

  // 3. Get Location
  if (kDebugMode) print("Getting current position...");
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      // Add timeout to prevent indefinite hang
      timeLimit: const Duration(seconds: 15),
    );
     if (kDebugMode) print("Position obtained: ${position.latitude}, ${position.longitude}");
    return position;
  } on TimeoutException {
     if (kDebugMode) print("Error getting location: Timed out.");
     return null; // Return null on timeout
  } catch (e) {
     if (kDebugMode) print("Error getting location: $e");
    return null; // Return null on other errors
  }
}


class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _timer;
  bool _isTracking = false; // Flag to prevent multiple start calls overlapping


  // Request location permissions using permission_handler
  Future<bool> requestLocationPermissions() async {
    if (kDebugMode) print("Requesting location permissions...");
    try {
      // Request foreground location permission.
      final foregroundStatus = await perm_handler.Permission.location.request();
      if (!foregroundStatus.isGranted) {
        if (kDebugMode) print("❌ Foreground location permission denied.");
        // Check if permanently denied
        if (foregroundStatus.isPermanentlyDenied) {
           if (kDebugMode) print("❌ Foreground location permission PERMANENTLY denied.");
           // Maybe guide user to settings here using openAppSettings() from permission_handler
        }
        return false;
      }
      if (kDebugMode) print("✅ Foreground location permission granted.");

      // --- Background Permission Handling (Optional, Requires Careful Setup) ---
      // Only request background if truly needed and manifest + foreground service are set up.
      /*
      if (await perm_handler.Permission.locationAlways.isGranted) {
         if (kDebugMode) print("✅ Background location permission already granted.");
         return true;
      } else {
         final backgroundStatus = await perm_handler.Permission.locationAlways.request();
         if (backgroundStatus.isGranted) {
             if (kDebugMode) print("✅ Background location permission granted NOW.");
             return true;
         } else {
             if (kDebugMode) print("⚠️ Background location permission not granted.");
             // Decide if foreground-only is acceptable
             return true; // Return true if foreground is enough
         }
      }
      */
      return true; // Return true based on foreground permission grant for now

    } catch (e) {
      if (kDebugMode) print("🚨 Exception during permission request: $e");
      return false;
    }
  }

  // Start location tracking.
  Future<void> startTracking({Duration interval = const Duration(seconds: 30)}) async { // Increased default interval
     if (kDebugMode) print("Attempting to start location tracking...");
     if (_isTracking) {
       if (kDebugMode) print("Location tracking is already active. Ignoring call.");
       return;
     }

    // Request permissions first
    final permissionsGranted = await requestLocationPermissions();
    if (!permissionsGranted) {
       if (kDebugMode) print("Cannot start tracking: Permissions not granted.");
      return; // Stop if permissions aren't granted
    }

    // Check service enabled status using Geolocator
     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
     if(!serviceEnabled){
         if (kDebugMode) print("Cannot start tracking: Location service is disabled.");
         // Optionally prompt user or wait
         return;
     }

    // Set tracking flag immediately to prevent race conditions
    _isTracking = true;

    if (kDebugMode) print("Permissions and service OK. Setting up periodic timer (interval: ${interval.inSeconds}s)...");

    // Prevent multiple timers if somehow startTracking is called again before _isTracking is set
    _timer?.cancel();

    // Run once immediately
    _performLocationUpdate();

    // Then run periodically
    _timer = Timer.periodic(interval, (Timer timer) async {
       if (!_isTracking) { // Check flag in case stopTracking was called
          timer.cancel();
          return;
       }
      _performLocationUpdate();
    });
     if (kDebugMode) print("Location tracking timer started.");
  }

  // Renamed internal function for clarity
  Future<void> _performLocationUpdate() async {
     if (kDebugMode) print("Timer tick: Performing location update...");
     try {
        // Get location using the internal helper which now returns Position?
        final Position? position = await getCurrentUserLocationInternal();

        if (position == null) {
          if (kDebugMode) print("⚠️ Failed to get location in timer tick, skipping update.");
          return; // Exit if location couldn't be obtained
        }

        if (kDebugMode) print("📍 Current Location: ${position.latitude}, ${position.longitude}");

        // ===>>> Send update to NATIVE side via MethodChannel <<<===
        _sendLocationToNative(position.latitude, position.longitude);
        // ========================================================

        // Also send to your external HTTP log endpoint
        await _sendLogToServer(position.latitude, position.longitude);

      } catch (e) {
        if (kDebugMode) print("🚨 Exception during Timer callback (_performLocationUpdate): $e");
        // Decide if tracking should stop on error
        // stopTracking();
      }
  }

  // --- Helper to Send Location to Native ---
  Future<void> _sendLocationToNative(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
       if (kDebugMode) print("Skipping native update: Invalid coordinates.");
      return; // Don't send invalid data
    }

    if (kDebugMode) print("Sending location to native...");
    try {
      final result = await _nativeLocationUpdateChannel.invokeMethod('updateLocation', {
        'latitude': latitude,
        'longitude': longitude,
      });
      if (kDebugMode) {
         print("✅ Location update sent to native successfully. Result: $result");
      }
    } on PlatformException catch (e) {
       if (kDebugMode) {
         print("❌ Failed to send location update to native: ${e.code} - ${e.message}");
       }
    } catch (e) {
       if (kDebugMode) {
         print("❌ Unexpected error sending location to native: $e");
       }
    }
  }

  // --- Helper to Send Log to External Server ---
  Future<void> _sendLogToServer(double? latitude, double? longitude) async {
      if (latitude == null || longitude == null) return;

       if (kDebugMode) print("Sending location log to external server...");
      try {
          final prefs = await SharedPreferences.getInstance();
          // Use default values or handle missing data appropriately
          final userID = prefs.getString("userID") ?? "unknown_userID";
          final username = prefs.getString("username") ?? "unknown_username";

          if (userID == "unknown_userID") {
            if (kDebugMode) print("⚠️ Error: UserID not found in SharedPreferences for server log.");
            // Consider if you should still send the log without userID
          }

          final timestamp = DateTime.now().toIso8601String();
          final payload = {
            "location": {
              "userid": userID,
              "username": username,
              "timestamp": timestamp,
              "lat": latitude,
              "long": longitude,
            },
          };

          final jsonPayload = jsonEncode(payload);
          final url = Uri.parse("http://20.255.248.234:5000/log"); // Your external endpoint

          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonPayload,
          ).timeout(const Duration(seconds: 10)); // Add timeout to HTTP request

          if (response.statusCode == 200) {
            if (kDebugMode) print("✅ Location log sent to server: ${response.body}");
          } else {
            if (kDebugMode) print("❌ Server responded with error ${response.statusCode}: ${response.body}");
          }
      } on TimeoutException {
           if (kDebugMode) print("❌ Timeout sending location log to server.");
      } catch (e) {
           if (kDebugMode) print("❌ Error sending location log to server: $e");
      }
  }

  // --- Stop Tracking ---
  void stopTracking() {
     if (kDebugMode) print('Stopping location tracking...');
    _timer?.cancel();
    _timer = null;
    _isTracking = false; // Update flag
     if (kDebugMode) print('Location tracking stopped.');
  }
}