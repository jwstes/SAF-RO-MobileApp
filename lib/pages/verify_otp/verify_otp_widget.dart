import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
// Import necessary pages for navigation
import '/pages/sign_in/sign_in_widget.dart'; // Import Sign In page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'verify_otp_model.dart'; // Import the model
export 'verify_otp_model.dart';

class VerifyOtpPageWidget extends StatefulWidget {
  const VerifyOtpPageWidget({
      super.key,
      this.email, // Optional parameter to display the email
  });

  final String? email; // Make email optional

  // Define route name and path
  static const String routeName = 'VerifyOtpPage';
  static const String routePath = '/verifyOtp'; // Simple path

  @override
  State<VerifyOtpPageWidget> createState() => _VerifyOtpPageWidgetState();
}

class _VerifyOtpPageWidgetState extends State<VerifyOtpPageWidget> {
  late VerifyOtpModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VerifyOtpModel());

    _model.otpFocusNode ??= FocusNode();
    _model.otpTextController ??= TextEditingController();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton( // Back button
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop(); // Go back
            },
          ),
          title: Text(
            'Verify Code',
            style: FlutterFlowTheme.of(context).headlineSmall,
          ),
          actions: const [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                // Center content vertically for this simple page
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                    child: Text(
                      'Enter the 6-digit code sent to your email or phone.', // Adjust text as needed
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).labelLarge,
                    ),
                  ),

                  // OTP Input Field
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                    child: TextFormField(
                      controller: _model.otpTextController,
                      focusNode: _model.otpFocusNode,
                      autofocus: true, // Focus when page loads
                      obscureText: false,
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                        labelStyle: FlutterFlowTheme.of(context).labelMedium,
                        hintText: 'Enter OTP...',
                        hintStyle: FlutterFlowTheme.of(context).labelMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).error,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).error,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: FlutterFlowTheme.of(context).primaryBackground,
                        contentPadding: const EdgeInsets.all(24.0),
                      ),
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6, // Limit input length
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Allow only digits
                      validator: _model.otpTextControllerValidator,
                    ),
                  ),

                  // Verify Button
                  FFButtonWidget(
                    onPressed: () async {
                      print('Verify OTP Button pressed');
                      // TODO: Add actual OTP verification logic here later

                      // For now, navigate to the Sign In page
                       context.pushReplacementNamed(SignInWidget.routeName);
                    },
                    text: 'Verify',
                    options: FFButtonOptions(
                      width: 200.0, // Fixed width button
                      height: 50.0,
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                      elevation: 3.0,
                      borderSide: const BorderSide(
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(30.0), // More rounded
                    ),
                  ),

                   // Optional: Resend Code Link
                   Padding(
                     padding: const EdgeInsets.only(top: 24.0),
                     child: TextButton(
                       onPressed: () {
                         // TODO: Implement resend OTP logic
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Resend OTP (Not Implemented)')),
                         );
                       },
                       child: Text(
                         'Resend Code?',
                         style: TextStyle(
                           color: FlutterFlowTheme.of(context).primary,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}