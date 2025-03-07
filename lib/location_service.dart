import 'dart:async';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<LatLng> getCurrentUserLocation({required LatLng defaultLocation}) async {
  try {
    // Check and request location permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print("Location permissions are denied.");
        return defaultLocation;
      }
    }
    // Get the current position with high accuracy.
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  } catch (e) {
    print("Error in getCurrentUserLocation: $e");
    return defaultLocation;
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _timer;

  // Starts a timer that fires every 5 seconds.
  void startTracking() {
    // If the timer is already active, no need to start it again.
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
      // Get the current location.
      final location = await getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0));
      print("Current Location: ${location.latitude}, ${location.longitude}");
      
      // Retrieve userID from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final userID = prefs.getString("userID") ?? "";
      if (userID.isEmpty) {
        print("Error: UserID not found in SharedPreferences.");
        return;
      }
      
      // Build the payload.
      final payload = jsonEncode({
        'userid': userID,
        'lat': location.latitude,
        'long': location.longitude,
      });
      
      // Define the URL for the update endpoint.
      final url = Uri.parse("http://10.0.2.2:3000/updateRealTimeLocation");
      
      try {
        // Send the POST request.
        final response = await http.post(url,
            headers: {"Content-Type": "application/json"}, body: payload);
        if (response.statusCode == 200) {
          print("Location updated successfully: ${response.body}");
        } else {
          print("Error updating location: ${response.body}");
        }
      } catch (e) {
        print("Exception while updating location: $e");
      }
    });
  }

  // Stops the timer.
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}