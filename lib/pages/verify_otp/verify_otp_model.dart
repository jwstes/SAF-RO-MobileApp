import '/flutter_flow/flutter_flow_util.dart';
import 'verify_otp_widget.dart' show VerifyOtpPageWidget; // Link to the widget file
import 'package:flutter/material.dart';

class VerifyOtpModel extends FlutterFlowModel<VerifyOtpPageWidget> {
  /// State fields for stateful widgets in this page.

  final unfocusNode = FocusNode(); // To handle unfocusing
  // State field for OTP input
  FocusNode? otpFocusNode;
  TextEditingController? otpTextController;
  String? Function(String?)? otpTextControllerValidator;
  // Optional: Add validator for OTP (e.g., check length, digits only)
  String? _otpValidator(String? val) {
      if (val == null || val.isEmpty) {
           return 'OTP cannot be empty.';
      }
      if (val.length != 6) { // Example: Assuming 6-digit OTP
           return 'Please enter a 6-digit OTP.';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(val)) {
           return 'OTP must contain only digits.';
      }
      return null;
  }


  @override
  void initState(BuildContext context) {
      // Initialize validator
      otpTextControllerValidator = _otpValidator;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    otpFocusNode?.dispose();
    otpTextController?.dispose();
  }
}