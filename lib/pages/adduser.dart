// ignore_for_file: public_member_api_docs, library_private_types_in_public_api

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/helpers.dart';
import 'package:p3pch4t/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  UserInfo? selfUi;

  final TextEditingController pkCtrl = TextEditingController();

  @override
  void initState() {
    p3p!.getSelfInfo().then((value) {
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
        title: const Text('Add new contact'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SelectableText(selfUi!.publicKey.fingerprint),
            TextField(
              controller: pkCtrl,
              minLines: 1,
              maxLines: 12,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                onPressed: () async {
                  final ui = await UserInfo.create(p3p!, pkCtrl.text);
                  if (ui == null) {
                    return;
                  }
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ),
            URQR(text: selfUi!.publicKey.publickey),
            const Text(
              'After scanning one part of qr, click the code to move to '
              'the next part',
            ),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton.icon(
                onPressed: scan,
                icon: const Icon(Icons.camera),
                label: const Text('Scan'),
              ),
            ),
            const Divider(),
            SelectableText(
              selfUi!.publicKey.publickey,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
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

      final list = cameraScanResult.split('|');
      final meta = list[0].split('/');
      total = int.parse(meta[1]);
      parts[int.parse(meta[0])] = list[1];
      setState(() {
        pkCtrl.text = parts.join();
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
