import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';

class DiscoveredUserPage extends StatelessWidget {
  const DiscoveredUserPage({required this.dui, super.key});

  final DiscoveredUserInfo dui;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dui.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SelectableText(dui.endpoint),
            SelectableText(dui.bio),
            SelectableText(dui.publickey),
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () {
          p3p.addUserFromPublicKey(dui.publickey, dui.name, dui.endpoint);
          Navigator.of(context).pop();
        },
        child: const Text('Add user'),
      ),
    );
  }
}
