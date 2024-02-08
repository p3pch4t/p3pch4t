// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/filemanager.dart';
import 'package:p3pch4t/pages/widgets/richtext.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.userInfo, super.key});

  final UserInfo userInfo;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final userInfo = widget.userInfo;
  final msgCtrl = TextEditingController();

  Iterable<Message> msgs = [];

  @override
  void initState() {
    loadMessages();
    scheduleLoadMessage();
    super.initState();
  }

  void loadMessages() {
    final newMsgs = p3p.getMessages(userInfo);
    if (!mounted) return;
    if (newMsgs.length == msgs.length) return;
    setState(() {
      msgs = newMsgs;
    });
  }

  void scheduleLoadMessage() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo.name),
      ),
      endDrawer: Drawer(
        child: FileManager(
          fileStore: userInfo.sharedFiles,
          roomFingerprint: userInfo.publicKey.fingerprint,
          chatroom: userInfo,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: msgs.length,
              itemBuilder: (context, index) {
                final msg = msgs.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: switch (msg.type) {
                    MessageType.text => SizedBox(
                        width: double.maxFinite,
                        child: RichTextView(
                          text: msg.text,
                          dateReceived: msg.dateReceived,
                          textAlign:
                              msg.incoming ? TextAlign.start : TextAlign.end,
                        ),
                      ),
                    MessageType.service => Center(
                        child: RichTextView(
                          text: msg.text,
                          dateReceived: msg.dateReceived,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _ => const Text('Unsupported message...'),
                  },
                );
              },
              shrinkWrap: true,
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: TextField(
              onSubmitted: (value) async {
                p3p.sendMessage(
                  userInfo,
                  msgCtrl.text,
                );
                loadMessages();
                msgCtrl.clear();
              },
              controller: msgCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
