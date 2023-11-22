// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({
    required this.userInfo,
    super.key,
  });

  final UserInfo userInfo;

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  late final endpointCtrl =
      TextEditingController(text: widget.userInfo.endpoint);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userInfo.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: endpointCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Endpoint'),
              ),
              onChanged: (String value) {
                widget.userInfo.endpoint = value;
              },
            ),
          ],
        ),
      ),
    );
  }
}
