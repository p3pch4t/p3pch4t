// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:p3p/p3p.dart';
import 'package:permission_handler/permission_handler.dart';

class FileView extends StatefulWidget {
  const FileView({
    required this.file,
    required this.roomFingerprint,
    super.key,
  });
  final SharedFile file;
  final String roomFingerprint;

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  late final file = widget.file;
  late final roomFingerprint = widget.roomFingerprint;

  late final pathCtrl = TextEditingController(text: file.filePath);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //SelectableText(const JsonEncoder.withIndent('   ').convert(file)),
            TextField(
              controller: pathCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton(
                child: const Text('open'),
                onPressed: () async {
                  if (Platform.isAndroid) {
                    await Permission.manageExternalStorage.request().isGranted;
                  }
                  final result = await OpenFile.open(file.localFilePath);
                  if (kDebugMode) {
                    print(result.message);
                  }
                },
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton(
                onPressed: () async {
                  file.delete();
                  await saveElement();
                },
                child: const Text('Delete file'),
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton(
                onPressed: saveElement,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveElement() async {
    if (kDebugMode) {
      print('saveElement:');
    }
    // file.filePath = pathCtrl.text;
    // await file.saveAndBroadcast(p3p!);
    setState(() {});
  }
}
