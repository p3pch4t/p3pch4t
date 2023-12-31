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
  final _si = p3p.getSelfInfo();
  late final nameCtrl = TextEditingController(text: _si.name);
  late final endpointCtrl = TextEditingController(text: _si.endpoint);

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
                  label: Text('Username'),
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: endpointCtrl,
                decoration: const InputDecoration(
                  label: Text('Endpoint'),
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
                  _si.name = nameCtrl.text;
                  _si.endpoint = endpointCtrl.text;
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
