import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
// Import http and convert for API calls

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Potentially import other pages if needed for navigation (e.g., ChatPage)
// import '/pages/chat_page/chat_page_widget.dart'; // Example
import 'find_friend_by_phone_model.dart';
export 'find_friend_by_phone_model.dart';

class FindFriendByPhonePageWidget extends StatefulWidget {
  const FindFriendByPhonePageWidget({super.key});

  // Define route name and path for navigation
  static const String routeName = 'FindFriendByPhonePage';
  static const String routePath = '/findFriendByPhone';

  @override
  State<FindFriendByPhonePageWidget> createState() =>
      _FindFriendByPhonePageWidgetState();
}

class _FindFriendByPhonePageWidgetState
    extends State<FindFriendByPhonePageWidget> {
  late FindFriendByPhoneModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FindFriendByPhoneModel());

    _model.phoneNumberFocusNode ??= FocusNode();
    _model.phoneNumberTextController ??= TextEditingController();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // --- Function to search for friend ---
  Future<void> _searchFriend() async {
    final String phoneNumber = _model.phoneNumberTextController?.text ?? '';
    if (phoneNumber.isEmpty) {
      setState(() {
        _model.searchError = "Please enter a phone number to search.";
        _model.searchResults = []; // Clear previous results
      });
      return;
    }

    // Unfocus the text field
    _model.phoneNumberFocusNode?.unfocus();

    // Set loading state
    setState(() {
      _model.isSearching = true;
      _model.searchError = null; // Clear previous errors
      _model.searchResults = []; // Clear previous results
    });

    try {
      // Use 20.255.248.234 for Android emulator accessing localhost, or your server IP
      final url = Uri.parse(
          "http://20.255.248.234/findFriendByPhoneNumber?phonenumber=${Uri.encodeComponent(phoneNumber)}");

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _model.searchResults = data;
          if (data.isEmpty) {
              _model.searchError = "No user found with that phone number.";
          }
        });
      } else if (response.statusCode == 404) {
         setState(() {
            _model.searchError = "No user found with that phone number.";
            _model.searchResults = [];
         });
      } else {
         setState(() {
           _model.searchError = "Error searching for friend (Code: ${response.statusCode})";
           _model.searchResults = [];
         });
      }
    } on TimeoutException {
       setState(() {
         _model.searchError = "Search timed out. Please try again.";
         _model.searchResults = [];
       });
    } catch (e) {
      setState(() {
        _model.searchError = "An error occurred: ${e.toString()}";
        _model.searchResults = [];
      });
    } finally {
      // Unset loading state
      setState(() {
        _model.isSearching = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
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
              context.pop(); // Go back to the previous page
            },
          ),
          title: Text(
            'Find Friend',
            style: FlutterFlowTheme.of(context).headlineMedium,
          ),
          actions: const [], // No actions needed for now
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Search Input Area ---
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                        child: TextFormField(
                          controller: _model.phoneNumberTextController,
                          focusNode: _model.phoneNumberFocusNode,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Friend\'s Phone Number',
                            labelStyle: FlutterFlowTheme.of(context).labelMedium,
                            hintText: 'Enter phone number...',
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            errorBorder: OutlineInputBorder( // Keep error borders
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                             focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            filled: true,
                            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          keyboardType: TextInputType.phone,
                          // Optional: Add validator if needed
                          // validator: _model.phoneNumberTextControllerValidator,
                          onFieldSubmitted: (_) => _searchFriend(), // Search on submit
                        ),
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: _searchFriend, // Call search function
                      text: 'Search',
                      icon: const Icon(
                        Icons.search,
                        size: 15.0,
                      ),
                      options: FFButtonOptions(
                        height: 45.0, // Slightly smaller button
                        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Inter',
                              color: Colors.white,
                            ),
                        elevation: 2.0,
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      showLoadingIndicator: _model.isSearching, // Show indicator while searching
                    ),
                  ],
                ),

                // --- Display Search Results or Error ---
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                  child: _buildSearchResults(), // Helper widget to build results
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widget to Build Search Results ---
  Widget _buildSearchResults() {
    if (_model.isSearching) {
      // return const Center(child: CircularProgressIndicator()); // Already handled by button indicator
      return Container(); // Return empty while button shows loading
    }

    if (_model.searchError != null) {
      return Center(
        child: Text(
          _model.searchError!,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: FlutterFlowTheme.of(context).error,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_model.searchResults.isEmpty) {
      // Don't show anything if search hasn't run or returned empty without error yet
      return Container();
    }

    // Display results in a ListView
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true, // Important for ListView inside Column
      itemCount: _model.searchResults.length,
      itemBuilder: (context, index) {
        final user = _model.searchResults[index];
        final String displayName = "${user['firstname'] ?? ''} ${user['lastname'] ?? ''}".trim();
        final String username = user['username'] ?? 'N/A';
        final String identifier = user['identifier'] ?? '';
        final int userId = user['userid']; // Assuming userid is needed for chat

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0), // Spacing between items
          child: ListTile(
            leading: Icon( // Placeholder Icon
                Icons.person_outline,
                color: FlutterFlowTheme.of(context).primary,
                size: 40,
             ),
            title: Text(
              displayName.isEmpty ? username : displayName, // Show username if name is empty
              style: FlutterFlowTheme.of(context).titleMedium,
            ),
            subtitle: Text(
              'ID: $identifier', // Show identifier
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: FlutterFlowTheme.of(context).secondaryText,
              size: 24.0,
            ),
            tileColor: FlutterFlowTheme.of(context).secondaryBackground,
            dense: false,
            shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(8.0),
            ),
            onTap: () {
               // TODO: Implement navigation to chat page or add friend action
               print('Tapped on user: $displayName (ID: $userId)');
               // Example navigation (ensure ChatPageWidget exists and takes parameters)
               /*
               context.pushNamed(
                   ChatPageWidget.routeName,
                   queryParameters: {
                       'recipientId': userId.toString(),
                       'recipientName': displayName,
                   }.withoutNulls,
               );
               */
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Navigate to chat with $displayName (Not implemented yet)')),
                 );
            },
          ),
        );
      },
    );
  }
}