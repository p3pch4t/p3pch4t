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
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: endpointCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Endpoint'),
                ),
                onChanged: (String value) {
                  widget.userInfo.endpoint = value;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.maxFinite,
                child: ElevatedButton(
                  onPressed: () {
                    final result = widget.userInfo.forceSendIntroduceEvent();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result
                              ? 'Introduce event queued'
                              : 'Unable to queue introduce event.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Force Introduce'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
