import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
export 'chat_model.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  static String routeName = 'Chat';
  static String routePath = '/chat';

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late ChatModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Recipient name loaded from SharedPreferences.
  String _recipientFirstName = "Chat";
  // Current user id (assumed stored as "userID")
  String _userID = "";
  // Recipient user id (stored from previous page)
  String _recipientID = "";
  // List of chat messages.
  List<Map<String, dynamic>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _loadChatData();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Load recipient first name, recipient id and current user id from SharedPreferences.
  Future<void> _loadChatData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recipientFirstName = prefs.getString("recipientFirstName") ?? "Chat";
      _recipientID = prefs.getString("recipientID") ?? "";
      _userID = prefs.getString("userID") ?? "";
    });
    await _loadChatMessages();
  }

  // Retrieve all chat messages between _userID and _recipientID from the backend.
  Future<void> _loadChatMessages() async {
    if (_userID.isEmpty || _recipientID.isEmpty) return;
    final url = Uri.parse(
        "http://10.0.2.2:3000/getChatMessages?userid=$_userID&recipientid=$_recipientID");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> messages = jsonDecode(response.body);
        setState(() {
          _chatMessages = messages
              .map<Map<String, dynamic>>((msg) => Map<String, dynamic>.from(msg))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading messages: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e")),
      );
    }
  }

  // Called when the user taps the Send button.
  Future<void> _sendMessage() async {
    final messageText = _model.textController!.text;
    if (messageText.isEmpty) return;

    // Create the payload using current user id, recipient id and message body.
    final payload = {
      'userid': _userID,
      'recipientid': _recipientID,
      'messagebody': messageText,
    };
    
    // Adjust the URL as needed. (For Android emulator, use http://10.0.2.2:3000)
    final url = Uri.parse('http://10.0.2.2:3000/sendMessage');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _chatMessages.add({
            'userid': _userID,
            'messagebody': messageText,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        });
        _model.textController!.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending message: ${response.body}"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus any active input fields.
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 40.0,
            icon: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 24.0,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Text(
            _recipientFirstName,
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Inter Tight',
                  letterSpacing: 0.0,
                ),
          ),
          actions: [
            Row(
              children: [
                FlutterFlowIconButton(
                  borderRadius: 8.0,
                  buttonSize: 40.0,
                  icon: Icon(
                    Icons.video_call,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 24.0,
                  ),
                  onPressed: () {
                    print('Video call pressed.');
                  },
                ),
              ].divide(SizedBox(width: 16.0)),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Chat messages area.
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Render dynamic messages.
                        ..._chatMessages.map((msg) {
                          // Convert msg['userid'] to string before comparing.
                          bool isSentByMe = msg['userid'].toString() == _userID;
                          return Row(
                            mainAxisAlignment: isSentByMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 4.0),
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: isSentByMe
                                      ? FlutterFlowTheme.of(context).primary
                                      : Color(0x3E000000),
                                  borderRadius: BorderRadius.only(
                                    topLeft: isSentByMe ? Radius.circular(20.0) : Radius.circular(4.0),
                                    topRight: isSentByMe ? Radius.circular(4.0) : Radius.circular(20.0),
                                    bottomLeft: Radius.circular(20.0),
                                    bottomRight: Radius.circular(20.0),
                                  ),
                                ),
                                child: Text(
                                  msg['messagebody'] ?? "",
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: isSentByMe
                                            ? FlutterFlowTheme.of(context).info
                                            : FlutterFlowTheme.of(context).primaryText,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              // Input area for new message.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0x3E000000),
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(4.0, 16.0, 4.0, 16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                    size: 24.0,
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _model.textController,
                                      focusNode: _model.textFieldFocusNode,
                                      autofocus: false,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        hintText: 'Type a message...',
                                        hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'Inter',
                                              letterSpacing: 0.0,
                                            ),
                                        border: InputBorder.none,
                                      ),
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                          ),
                                      minLines: 1,
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await _sendMessage();
                          },
                          child: Container(
                            width: 48.0,
                            height: 48.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Icon(
                                Icons.send,
                                color: FlutterFlowTheme.of(context).info,
                                size: 24.0,
                              ),
                            ),
                          ),
                        ),
                      ].divide(SizedBox(width: 16.0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}