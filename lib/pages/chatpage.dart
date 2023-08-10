import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.userInfo}) : super(key: key);

  final UserInfo userInfo;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final userInfo = widget.userInfo;
  final msgCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    print(userInfo.messages.length);
    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: userInfo.messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  subtitle: Text(userInfo.messages[index].text),
                );
              },
              shrinkWrap: true,
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: TextField(
              onSubmitted: (value) async {
                await p3p.sendMessage(userInfo, msgCtrl.text, null);
                await userInfo.refresh(p3p.userinfoBox);
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
