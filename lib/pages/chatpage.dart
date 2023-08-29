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

  List<Message> msgs = [];

  @override
  void initState() {
    loadMessages();
    loadMessageCallback();
    super.initState();
  }

  @override
  void dispose() {
    p3p!.onMessageCallback.removeAt(_messageCallbackIndex);
    super.dispose();
  }

  int _messageCallbackIndex = -1;
  void loadMessageCallback() {
    p3p!.onMessageCallback.add(_messageCallback);
    setState(() {
      _messageCallbackIndex = p3p!.onMessageCallback.length - 1;
    });
  }

  Future<void> _messageCallback(P3p p3p, Message msg, UserInfo ui) async {
    if (ui.id != userInfo.id) return; // only current open chat events
    await loadMessages();
  }

  Future<void> loadMessages() async {
    final newMsgs = await userInfo.getMessages(p3p!);
    if (!mounted) return;
    setState(() {
      msgs = newMsgs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rmsgs = msgs.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo.name ?? 'name unknown'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return FileManager(
                      fileStore: userInfo.fileStore,
                      roomFingerprint: userInfo.publicKey.fingerprint,
                      chatroom: userInfo,
                    );
                  },
                ),
              );
              await loadMessages();
            },
            icon: const Icon(Icons.folder),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: rmsgs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: switch (rmsgs[index].type) {
                    MessageType.text => SizedBox(
                        width: double.maxFinite,
                        child: RichTextView(
                          text: rmsgs[index].text,
                          dateReceived: rmsgs[index].dateReceived,
                          textAlign: rmsgs[index].incoming
                              ? TextAlign.start
                              : TextAlign.end,
                        ),
                      ),
                    MessageType.service => Center(
                        child: RichTextView(
                          text: rmsgs[index].text,
                          dateReceived: rmsgs[index].dateReceived,
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
                await p3p!.sendMessage(
                  userInfo,
                  msgCtrl.text,
                );
                await loadMessages();
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
