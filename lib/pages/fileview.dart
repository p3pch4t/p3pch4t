import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:permission_handler/permission_handler.dart';

class FileView extends StatefulWidget {
  const FileView({
    required this.file,
    required this.roomFingerprint,
    super.key,
  });
  final FileStoreElement file;
  final String roomFingerprint;

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  late final file = widget.file;
  late final roomFingerprint = widget.roomFingerprint;

  late final pathCtrl = TextEditingController(text: file.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (file.downloadedSizeBytes != file.sizeBytes)
              LinearProgressIndicator(
                value: file.downloadedSizeBytes == 0
                    ? null
                    : file.downloadedSizeBytes / file.sizeBytes,
              ),
            SelectableText(const JsonEncoder.withIndent('   ').convert(file)),
            TextField(
              controller: pathCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton(
                child: const Text('open (may not work)'),
                onPressed: () async {
                  if (Platform.isAndroid) {
                    await Permission.manageExternalStorage.request().isGranted;
                  }
                  final result = await OpenFile.open(file.localPath);
                  if (kDebugMode) {
                    print(result.message);
                  }
                },
              ),
            ),
            CheckboxListTile(
              title: const Text('Should sync'),
              value: file.shouldFetch,
              onChanged: (bool? value) async {
                file.shouldFetch = value!;
                await saveElement();
              },
            ),
            CheckboxListTile(
              title: const Text('Is deleted?'),
              value: file.isDeleted,
              onChanged: (bool? value) async {
                file.isDeleted = value!;
                await saveElement();
              },
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
    file.path = pathCtrl.text;
    await file.save(p3p!);
    setState(() {});
  }
}
