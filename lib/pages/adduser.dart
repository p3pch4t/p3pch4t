// ignore_for_file: public_member_api_docs, library_private_types_in_public_api

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/duipage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  UserInfo selfUi = p3p.getSelfInfo();

  final TextEditingController urlCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new contact'),
      ),
      body: SingleChildScrollView(
        child: Column(
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
          ],
        ),
      ),
    );
  }

  Future<void> scan() async {
    var total = 9999;
    final parts = List.generate(total, (index) => '');
    await Permission.camera.request();
    while (true) {
      final cameraScanResult = await scanner.scan();
      if (cameraScanResult == null) break;
      print('scan:$cameraScanResult');
      final list = cameraScanResult.split('|');
      final meta = list[0].split('/');
      total = int.parse(meta[1]);
      parts[int.parse(meta[0])] = list[1];
      setState(() {
        urlCtrl.text = parts.join();
      });
      var done = true;
      for (var i = 0; i < total; i++) {
        if (parts[i] == '') done = false;
      }
      if (done) {
        break;
      }
    }
  }
}

class URQR extends StatefulWidget {
  const URQR({required this.text, super.key});

  final String text;

  @override
  _URQRState createState() => _URQRState();
}

class _URQRState extends State<URQR> {
  late List<String> texts;
  final int divider = 500;
  @override
  void initState() {
    final tmpList = <String>[];
    for (var i = 0; i < widget.text.length; i++) {
      if (i % divider == 0) {
        final tempString =
            widget.text.substring(i, min(i + divider, widget.text.length));
        tmpList.add(tempString);
      }
    }
    setState(() {
      texts = tmpList;
    });

    super.initState();
  }

  int i = 0;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          i = (i + 1) % texts.length;
        });
      },
      child: QrImageView(
        data: '$i/${texts.length}|${texts[i]}',
        backgroundColor: Colors.white,
      ),
    );
  }
}
