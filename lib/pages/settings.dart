// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_i2p/flutter_i2p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final nameCtrl = TextEditingController();

  @override
  void initState() {
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
                onPressed: i2p == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                I2pConfigPage(i2pdConf: i2p!.i2pdConf),
                          ),
                        );
                      },
                child: const Text('I2p settings'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final si = await p3p!.getSelfInfo();
                  si.name = nameCtrl.text;
                  si.id = await p3p!.db.save(si);
                  await p3p!.db.getAllUserInfo().then((value) async {
                    for (final element in value) {
                      element.lastIntroduce = DateTime(1998);
                      element.id = await p3p!.db.save(element);
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
