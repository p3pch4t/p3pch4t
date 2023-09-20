// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_i2p/flutter_i2p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/platform_interface.dart';
import 'package:path_provider/path_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final nameCtrl = TextEditingController();

  @override
  void initState() {
    getAndroidNativeLibraryDirectory().then(print);
    p3p!.getSelfInfo().then((value) {
      setState(() {
        nameCtrl.text = value.name ?? 'Unknown';
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const I2pConfigPage(),
                    ),
                  );
                },
                child: const Text('I2p settings'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final si = await p3p!.getSelfInfo();
                  si.name = nameCtrl.text;
                  await p3p!.db.save(si);
                  await p3p!.db.getAllUserInfo().then((value) {
                    for (final element in value) {
                      element.lastIntroduce = DateTime(1998);
                      p3p!.db.save(element);
                    }
                  });
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Save and exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
