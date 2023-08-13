import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/fileview.dart';
import 'package:p3pch4t/pages/webxdcfileview.dart';

import 'package:path/path.dart' as p;

class FileManager extends StatefulWidget {
  const FileManager({
    Key? key,
    required this.fileStore,
    required this.roomId,
    required this.chatroom,
  }) : super(key: key);
  final FileStore fileStore;
  final String roomId;
  final UserInfo chatroom;

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  late final fileStore = widget.fileStore;
  late final roomId = widget.roomId;
  late final chatroom = widget.chatroom;

  List<FileStoreElement> files = [];
  String path = "/";

  @override
  void initState() {
    loadFiles();
    super.initState();
  }

  void loadFiles() async {
    final newFiles =
        await fileStore.getFileStoreElement(p3p.filestoreelementBox);
    setState(() {
      files = newFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inScopeAll = files.where((elm) => elm.path.startsWith(path)).toList();
    var inScopeDirectories = <String>[];
    if (path != "/") {
      inScopeDirectories.add("..");
    }
    for (var file in inScopeAll) {
      if (file.path == p.join(path, p.basename(file.path))) continue;

      String fs1 = file.path.substring(path.length);
      if (fs1.startsWith('/')) fs1 = fs1.substring(1);

      inScopeDirectories.add(fs1.substring(0, fs1.indexOf('/')));
    }
    inScopeDirectories = inScopeDirectories.toSet().toList();
    final inScopeFiles = inScopeAll
        .where((elm) => !elm.path.substring(path.length + 1).contains('/'))
        .where((elm) => kDebugMode || !p.basename(elm.path).startsWith('.'))
        .where((elm) => !elm.isDeleted)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(path),
      ),
      body: ListView.builder(
        itemCount: inScopeFiles.length + inScopeDirectories.length,
        itemBuilder: (context, index) {
          if (inScopeDirectories.length > index) {
            return renderDirectory(inScopeDirectories[index]);
          }
          return renderFile(
              inScopeFiles[index - inScopeDirectories.length], roomId);
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result == null) return;
        if (result.files.isEmpty) return;
        for (var file in result.files) {
          DateTime today = DateTime.now();
          String dateSlug =
              "${today.year.toString()}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
          await fileStore.putFileStoreElement(
            p3p.filestoreelementBox,
            p3p.userinfoBox,
            File(file.path!),
            FileStoreElement.calcSha512Sum(
                await File(file.path!).readAsBytes()),
            await File(file.path!).length(),
            p.join('/Unsort', dateSlug, file.name),
            p3p.fileStorePath,
          );
          loadFiles();
        }
        loadFiles();
      }),
    );
  }

  Card renderFile(FileStoreElement file, String roomId) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description),
        title: Text(
          p.basename(file.path),
          maxLines: 1,
        ),
        subtitle:
            Text("${(file.sizeBytes / 1024 / 1024).toStringAsFixed(4)} MiB"),
        onLongPress: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FileView(
                file: file,
                roomId: roomId,
              ),
            ),
          );
          loadFiles();
        },
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return switch (file.path.split('.').reversed.first) {
                  "xdc" => WebxdcFileView(
                      file: file,
                      roomId: roomId,
                      chatroom: chatroom,
                    ),
                  _ => FileView(
                      file: file,
                      roomId: roomId,
                    )
                };
              },
            ),
          );
          loadFiles();
        },
      ),
    );
  }

  Card renderDirectory(String directory) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: Text(p.basename(directory)),
        onTap: () {
          setState(() {
            path = p.normalize(p.join(path, directory));
          });
        },
      ),
    );
  }
}
