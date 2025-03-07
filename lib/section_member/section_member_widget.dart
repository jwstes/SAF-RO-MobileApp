import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'section_member_model.dart';
export 'section_member_model.dart';

// Helper function to convert numeric role to a display string.
String getRoleName(dynamic role) {
  if (role == 0) return "Soldier";
  if (role == 1) return "Platoon Sergeant";
  if (role == 2) return "Platoon Commander";
  return "Unknown";
}

class SectionMemberWidget extends StatefulWidget {
  const SectionMemberWidget({super.key});

  static String routeName = 'SectionMember';
  static String routePath = '/sectionMember';

  @override
  State<SectionMemberWidget> createState() => _SectionMemberWidgetState();
}

class _SectionMemberWidgetState extends State<SectionMemberWidget> {
  late SectionMemberModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables for current user's role and section.
  String _roleNumber = "";
  String _sectionNumber = "";

  // Future for the fetched section users.
  Future<List<dynamic>>? _futureUsers;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SectionMemberModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _loadUserInfoAndData();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Load the current user's role and section number from SharedPreferences
  // then trigger the fetch for section users.
  Future<void> _loadUserInfoAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _roleNumber = prefs.getString("roleNumber") ?? "";
      _sectionNumber = prefs.getString("sectionNumber") ?? "";
      _futureUsers = fetchUsersBySection(_sectionNumber);
    });
  }

  // Call the /getUsersBySection endpoint using the given section number.
  Future<List<dynamic>> fetchUsersBySection(String section) async {
    final url = Uri.parse("http://10.0.2.2:3000/getUsersBySection?section=$section");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);
      return users;
    } else {
      throw Exception("Failed to load section users");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus all inputs.
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (responsiveVisibility(
                context: context,
                phone: false,
                tablet: false,
              ))
                Container(
                  width: 270.0,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_task_rounded,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 32.0,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  'check.io',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        fontFamily: 'Inter Tight',
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 12.0,
                          thickness: 2.0,
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                        // Additional sidebar content…
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    // Header area with title and back button.
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 8.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              context.safePop();
                            },
                            child: Icon(
                              Icons.arrow_back,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 0.0, 4.0),
                            child: Text(
                              'Section Members',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 8.0),
                      child: Text(
                        'Below is the list of members in your section.',
                        style: FlutterFlowTheme.of(context).labelMedium.override(
                              fontFamily: 'Inter',
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                    // Search bar.
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 0.0),
                      child: TextFormField(
                        controller: _model.textController,
                        focusNode: _model.textFieldFocusNode,
                        autofocus: true,
                        obscureText: false,
                        decoration: InputDecoration(
                          labelText: 'Search all users...',
                          labelStyle: FlutterFlowTheme.of(context).labelMedium
                              .override(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          suffixIcon: Icon(
                            Icons.search_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              letterSpacing: 0.0,
                            ),
                        cursorColor: FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                    // Build the dynamic list of section members.
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _futureUsers,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text("Error: ${snapshot.error}"));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text("No section members found"));
                          } else {
                            final users = snapshot.data!;
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 0.0,
                                        color: FlutterFlowTheme.of(context).alternate,
                                        offset: Offset(0.0, 1.0),
                                      )
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 12.0, 16.0, 12.0),
                                    child: Row(
                                      children: [
                                        // User avatar.
                                        Container(
                                          width: 44.0,
                                          height: 44.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .accent1,
                                            borderRadius: BorderRadius.circular(12.0),
                                            border: Border.all(
                                              color: FlutterFlowTheme.of(context)
                                                  .primary,
                                              width: 2.0,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(2.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8.0),
                                              child: CachedNetworkImage(
                                                imageUrl: user["avatar"] ??
                                                    "https://via.placeholder.com/150",
                                                width: 44.0,
                                                height: 44.0,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // User details: name with role and username.
                                        Expanded(
                                          flex: 4,
                                          child: Padding(
                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                12.0, 0.0, 0.0, 0.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${user["firstname"] ?? "No Name"} | ${getRoleName(user["role"])}',
                                                  style: FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                                Text(
                                                  user["username"] ?? "",
                                                  style: FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (responsiveVisibility(context: context, phone: false))
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 12.0, 0.0),
                                              child: Text(
                                                user["lastActive"] ?? "N/A",
                                                style: FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .override(
                                                      fontFamily: 'Inter',
                                                      letterSpacing: 0.0,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        if (responsiveVisibility(context: context, phone: false, tablet: false))
                                          Expanded(
                                            flex: 3,
                                            child: Align(
                                              alignment: AlignmentDirectional(-1.0, 0.0),
                                              child: Text(
                                                user["title"] ?? "",
                                                style: FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .override(
                                                      fontFamily: 'Inter',
                                                      letterSpacing: 0.0,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        // Action buttons.
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () async {
                                                  final prefs = await SharedPreferences.getInstance();
                                                  // Use "userid" from your backend data instead of "id".
                                                  await prefs.setString("recipientID", (user["userid"] ?? "").toString());
                                                  await prefs.setString("recipientUsername", user["username"] ?? "");
                                                  await prefs.setString("recipientFirstName", user["firstname"] ?? "");
                                                  context.pushNamed(ChatWidget.routeName);
                                                },
                                                child: Container(
                                                  constraints: BoxConstraints(minWidth: 100.0),
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(context).accent3,
                                                    borderRadius: BorderRadius.circular(8.0),
                                                    border: Border.all(
                                                      color: FlutterFlowTheme.of(context).tertiary,
                                                    ),
                                                  ),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0.0, 0.0),
                                                    child: Padding(
                                                      padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                                      child: Text(
                                                        'Chat',
                                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                                              fontFamily: 'Inter',
                                                              letterSpacing: 0.0,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // If current user’s role equals "2" (Platoon Commander),
                                              // an extra X button appears.
                                              if (_roleNumber == "2")
                                                Padding(
                                                  padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
                                                  child: InkWell(
                                                    onTap: () {
                                                      print("Extra X tapped for user: ${user["userid"]}");
                                                    },
                                                    child: Icon(
                                                      Icons.close,
                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                      size: 24.0,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}