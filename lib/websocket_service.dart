import 'dart:convert';
import 'dart:math';
import 'dart:async'; // For StreamSubscription
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:web_socket_channel/web_socket_channel.dart';
import 'native_command_handler.dart'; // We will create this next

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription; // To manage the listener
  String? _userId;
  // ▼▼▼ IMPORTANT: Replace with your actual backend IP/domain and port ▼▼▼
  final String _wsUrl = 'ws://20.255.248.234';
  // ▲▲▲ IMPORTANT: Replace with your actual backend IP/domain and port ▲▲▲
  final NativeCommandHandler _commandHandler = NativeCommandHandler(); // Handler for commands

  String? get userId => _userId;

  // Singleton pattern
  WebSocketService._privateConstructor();
  static final WebSocketService _instance = WebSocketService._privateConstructor();
  factory WebSocketService() {
    return _instance;
  }

  void connectAndRegister() {
    // Prevent multiple connections
    if (_channel != null && _channel?.closeCode == null) {
       if (kDebugMode) {
         print('WebSocket already connected or connecting.');
       }
      // If already registered, maybe send a ping or re-register if needed
      if(_userId != null) _registerDevice(); // Re-register just in case
      return;
    }

     if (kDebugMode) {
       print('WebSocket attempting to connect...');
     }

    // Generate random User ID (1-50) if not already set
    _userId ??= (Random().nextInt(50) + 1).toString();
     if (kDebugMode) {
       print('Using User ID: $_userId');
     }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
       if (kDebugMode) {
         print('WebSocket connecting to $_wsUrl...');
       }

      // Cancel previous subscription if it exists and wasn't properly closed
      _channelSubscription?.cancel();

      _channelSubscription = _channel!.stream.listen(
        (message) {
          if (kDebugMode) {
            print('WebSocket received: $message');
          }
          _handleMessage(message);
        },
        onDone: () {
           if (kDebugMode) {
             print('WebSocket disconnected. User ID: $_userId. Attempting reconnect...');
           }
          _channel = null; // Mark as disconnected
          _channelSubscription = null;
          // Attempt to reconnect after a delay
          Future.delayed(const Duration(seconds: 5), connectAndRegister);
        },
        onError: (error) {
           if (kDebugMode) {
             print('WebSocket error: $error. Attempting reconnect...');
           }
          _channel = null; // Mark as potentially disconnected
          _channelSubscription?.cancel(); // Cancel subscription on error too
          _channelSubscription = null;
          // Attempt to reconnect after a delay
          Future.delayed(const Duration(seconds: 5), connectAndRegister);
        },
        cancelOnError: false, // Let onDone handle reconnect logic usually
      );

       // Send registration message shortly after initiating connection attempt
       // Using a small delay to increase chances the connection is ready
       Future.delayed(const Duration(milliseconds: 500), _registerDevice);


       if (kDebugMode) {
         print('WebSocket connection listener set up. Registration pending.');
       }

    } catch (e) {
       if (kDebugMode) {
         print('WebSocket connection error during connect: $e. Retrying...');
       }
      _channel = null; // Ensure channel is null on error
      _channelSubscription = null; // Ensure subscription is null
      // Attempt to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), connectAndRegister);
    }
  }

  void _registerDevice() {
     // Only send if channel exists and closeCode is null (meaning not actively closed)
    if (_channel != null && _userId != null && _channel?.closeCode == null) {
      final message = jsonEncode({
        'type': 'register',
        'userId': _userId,
      });
      try {
          _channel!.sink.add(message);
           if (kDebugMode) {
             print('WebSocket sent registration: $message');
           }
      } catch (e) {
           if (kDebugMode) {
             print('WebSocket error sending registration: $e');
             // This might indicate the connection failed immediately after creation
             // The onError/onDone handlers should manage reconnection.
           }
      }
    } else {
       if (kDebugMode) {
         print('WebSocket cannot register: Channel is null, closing, or User ID is null.');
         // If channel is null, connectAndRegister should be triggered again by error/done handlers
       }
    }
  }

  
  void _handleMessage(String message) {
  try {
    // Log 1: Raw message from WebSocket
    if (kDebugMode) {
       print('[WebSocketService._handleMessage] Raw message received: $message');
    }

    final data = jsonDecode(message);

    // Log 2: Parsed JSON data
    if (kDebugMode) {
       print('[WebSocketService._handleMessage] Parsed data: $data');
    }

    if (data['type'] == 'execute_command' && data['commandId'] != null && data['command'] != null) {
      final String commandId = data['commandId'];
      final String command = data['command'];
      // Extract args carefully
      final dynamic args = data['args']; // Get the value associated with the 'args' key

      // Log 3: Extracted values BEFORE calling handler
      if (kDebugMode) {
        print('[WebSocketService._handleMessage] Processing execute_command:');
        print('  -> commandId: $commandId (Type: ${commandId.runtimeType})');
        print('  -> command: $command (Type: ${command.runtimeType})');
        // ===>>> CRITICAL LOGGING FOR 'args' <<<===
        if (args == null) {
            print('  -> args: IS NULL');
        } else {
            print('  -> args: $args (Type: ${args.runtimeType})');
        }
        // =========================================
      }

      // Pass extracted values to the handler
      _commandHandler.handleCommand(command, commandId, args, _sendResult);

    } else if (data['type'] == 'registered') {
       if (kDebugMode) { print("[WebSocketService._handleMessage] Registration confirmed."); }
    } else if (data['type'] == 'error') {
        if (kDebugMode) { print("[WebSocketService._handleMessage] Server error: ${data['message']}"); }
    } else {
        if (kDebugMode) { print("[WebSocketService._handleMessage] Unhandled message type: ${data['type']}"); }
    }
  } catch (e, stackTrace) { // Catch stack trace too
     if (kDebugMode) {
       print('[WebSocketService._handleMessage] Error handling message: $e');
       print('[WebSocketService._handleMessage] Stack Trace: $stackTrace'); // Print stack trace
     }
  }
}


  // Callback function for NativeCommandHandler to send results back
  void _sendResult(String commandId, dynamic output, String? error) {
     if (_channel != null && _channel?.closeCode == null) {
      final message = jsonEncode({
        'type': 'command_result',
        'commandId': commandId,
        // Conditionally include 'output' or 'error'
        if (error != null) 'error': error else 'output': output,
      });
       if (kDebugMode) {
         print('WebSocket sending result: $message');
       }
       try {
            _channel!.sink.add(message);
       } catch (e) {
           if (kDebugMode) {
             print('WebSocket error sending result: $e');
           }
       }
    } else {
       if (kDebugMode) {
         print('WebSocket cannot send result: Channel is closed or null.');
       }
    }
  }

  void dispose() {
     if (kDebugMode) {
       print('WebSocket disposing connection. User ID: $_userId');
     }
    _channelSubscription?.cancel(); // Cancel the listener
    _channel?.sink.close(); // Close the connection sink
    _channel = null;
    _channelSubscription = null;
    // Do not reset userId here, it might be needed for quick reconnect
  }
}