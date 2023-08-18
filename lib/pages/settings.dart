import 'package:flutter/material.dart';
import 'package:p3pch4t/main.dart';

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
                onPressed: () async {
                  final si = await p3p!.getSelfInfo();
                  si.name = nameCtrl.text;
                  await si.save(p3p!);
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
