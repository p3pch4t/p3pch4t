import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/filemanager.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.userInfo}) : super(key: key);

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
    super.initState();
  }

  void loadMessages() async {
    final newMsgs = await userInfo.getMessages(p3p);
    setState(() {
      msgs = newMsgs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rmsgs = msgs.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo.name ?? "name unknown"),
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
                loadMessages();
              },
              icon: const Icon(Icons.folder)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: rmsgs.length,
              itemBuilder: (context, index) {
                return switch (rmsgs[index].type) {
                  MessageType.text => ListTile(
                      title: SizedBox(
                        width: double.maxFinite,
                        child: Text(
                          rmsgs[index].text,
                          textAlign: rmsgs[index].incoming
                              ? TextAlign.start
                              : TextAlign.end,
                        ),
                      ),
                      // subtitle: kDebugMode ? Text(rmsgs[index].debug()) : null,
                    ),
                  MessageType.service => Center(child: Text(rmsgs[index].text)),
                  _ => const Text("Unsupported message..."),
                };
              },
              shrinkWrap: true,
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: TextField(
              onSubmitted: (value) async {
                await p3p.sendMessage(userInfo, msgCtrl.text,
                    type: MessageType.text);
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
