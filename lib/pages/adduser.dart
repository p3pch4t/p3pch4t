import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/helpers.dart';
import 'package:p3pch4t/main.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({Key? key}) : super(key: key);

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  UserInfo? selfUi;

  final TextEditingController pkCtrl = TextEditingController();

  @override
  void initState() {
    p3p.getSelfInfo().then((value) {
      setState(() => selfUi = value);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (selfUi == null || selfUi?.publicKey == null) {
      return const LoadingPlaceholder();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add new contact"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SelectableText("FP: ${selfUi!.publicKey.fingerprint}"),
            SelectableText(
              selfUi!.publicKey.publickey,
              style: const TextStyle(fontSize: 7),
            ),
            TextField(
              controller: pkCtrl,
              maxLines: 16,
              minLines: 16,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                final ui = await UserInfo.create(pkCtrl.text, p3p.userinfoBox);
                if (ui == null) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }
}
