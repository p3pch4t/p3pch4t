// ignore_for_file: public_member_api_docs, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/duipage.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  UserInfo selfUi = p3p.getSelfInfo();

  final TextEditingController urlCtrl = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new contact'),
      ),
      body: Column(
        children: [
          SelectableText(p3p.getSelfInfo().endpoint),
          const Divider(),
          TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(
              label: Text('Endpoint'),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: () async {
                final dui = p3p.getUserDetailsByURL(urlCtrl.text);
                if (dui == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to reach given user.'),
                    ),
                  );
                  return;
                }
                if (!mounted) return;
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return DiscoveredUserPage(dui: dui);
                    },
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ),
          Expanded(
            child: Container(),
          ),
        ],
      ),
    );
  }
}
