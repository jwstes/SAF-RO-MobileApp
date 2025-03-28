import 'dart:async';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/*Future<LatLng> getCurrentUserLocation({required LatLng defaultLocation}) async {
  try {
    // Check if location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
  // Prompt user
    await Geolocator.openLocationSettings();
    print("🛠 Prompted user to enable location.");
  }


    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  } catch (e) {
    print("Error in getCurrentUserLocation: $e");
    return defaultLocation;
  }
} */
Future<LatLng> getCurrentUserLocation({required LatLng defaultLocation}) async {
  while (!(await Geolocator.isLocationServiceEnabled())) {
    print("⏳ Waiting for user to enable location...");
    await Geolocator.openLocationSettings();
    await Future.delayed(Duration(seconds: 2));
  }
  print("✅ Location services now enabled.");
  try {
    // Check if location services are enabled.
    
    Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  } catch (e) {
    print("Error retrieving location: $e");
    return defaultLocation;
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _timer;

  // 🔐 Request both foreground & background location permissions.
  Future<bool> requestLocationPermissions() async {
    try {
      // Request foreground location permission.
      final foregroundStatus = await Permission.location.request();
      if (!foregroundStatus.isGranted) {
        print("❌ Foreground location permission denied.");
        return false;
      }
      print("✅ Foreground location permission granted.");
      return true;
      // Request background location permission.
      //final backgroundStatus = await Permission.locationAlways.request();
      /*if (backgroundStatus.isGranted) {
        print("✅ Background location permission granted.");
        print("✅ Full location permissions granted.");
        return true;
      } else {
        print("⚠️ Background location permission not granted. "
              "App will function only while in the foreground.");
        // If your app can work in foreground-only mode, you may choose to return true.
        // Otherwise, return false to enforce background tracking.
        return true;
      } */
    } 
    catch (e) {
      print("🚨 Exception during permission request: $e");
      return false;
    }
  } 

  // 🚀 Starts location tracking.
  Future<void> startTracking({Duration interval = const Duration(seconds: 100)}) async {
    final permissionsGranted = await requestLocationPermissions();
    if (!permissionsGranted) return;

    // Prevent multiple timers.
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(interval, (Timer timer) async {
      try {
        // Optionally, add a slight delay to let the system settle after permissions change.
        await Future.delayed(const Duration(milliseconds: 10));
        final location = await getCurrentUserLocation(
          defaultLocation: LatLng(0.0, 0.0),
        );
        print("📍 Current Location: ${location.latitude}, ${location.longitude}");

        final prefs = await SharedPreferences.getInstance();
        final userID = prefs.getString("userID") ?? "";
        final username = prefs.getString("username") ?? "";

        if (userID.isEmpty) {
          print("⚠️ Error: UserID not found in SharedPreferences.");
          return;
        }

        final timestamp = DateTime.now().toIso8601String();
        final payload = {
          "location": {
            "userid": userID,
            "username": username,
            "timestamp": timestamp,
            "lat": location.latitude,
            "long": location.longitude,
          },
        };

        final jsonPayload = jsonEncode(payload);
        final url = Uri.parse("http://20.255.248.234:5000/log");

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonPayload,
        );
        if (response.statusCode == 200) {
          print("✅ Location updated: ${response.body}");
        } else {
          print("❌ Server responded with error: ${response.body}");
        }
      } catch (e) {
        print("🚨 Exception during Timer callback: $e");
      }
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}
