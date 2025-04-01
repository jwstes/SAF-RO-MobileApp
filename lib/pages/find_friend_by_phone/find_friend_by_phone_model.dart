import '/flutter_flow/flutter_flow_util.dart';
// Import other necessary FlutterFlow models or utils if needed
import 'find_friend_by_phone_widget.dart' show FindFriendByPhonePageWidget;
import 'package:flutter/material.dart';

class FindFriendByPhoneModel
    extends FlutterFlowModel<FindFriendByPhonePageWidget> {
  /// State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field for PhoneNumber TextField
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  String? Function(BuildContext, String?)? phoneNumberTextControllerValidator;

  // State for API call loading status
  bool isSearching = false;
  // State to store search results (List of user maps)
  List<dynamic> searchResults = [];
  // State to store error message
  String? searchError;


  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();
  }
}