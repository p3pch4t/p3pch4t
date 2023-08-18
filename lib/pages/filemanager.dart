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
    required this.fileStore,
    required this.roomFingerprint,
    required this.chatroom,
    super.key,
  });
  final FileStore fileStore;
  final String roomFingerprint;
  final UserInfo chatroom;

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  late final fileStore = widget.fileStore;
  late final roomFingerprint = widget.roomFingerprint;
  late final chatroom = widget.chatroom;

  List<FileStoreElement> files = [];
  String path = '/';

  @override
  void initState() {
    loadFiles();
    super.initState();
  }

  Future<void> loadFiles() async {
    final newFiles = await fileStore.getFileStoreElement(p3p!);
    setState(() {
      files = newFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inScopeAll = files.where((elm) => elm.path.startsWith(path)).toList();
    var inScopeDirectories = <String>[];
    if (path != '/') {
      inScopeDirectories.add('..');
    }
    for (final file in inScopeAll) {
      if (file.path == p.join(path, p.basename(file.path))) continue;

      var fs1 = file.path.substring(path.length);
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
            inScopeFiles[index - inScopeDirectories.length],
            roomFingerprint,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles();
          if (result == null) return;
          if (result.files.isEmpty) return;
          for (final file in result.files) {
            final today = DateTime.now();
            final dateSlug =
                "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
            await fileStore.putFileStoreElement(
              p3p!,
              localFile: File(file.path!),
              localFileSha512sum: FileStoreElement.calcSha512Sum(
                await File(file.path!).readAsBytes(),
              ),
              sizeBytes: await File(file.path!).length(),
              fileInChatPath: '/Unsort/$dateSlug/${file.name}',
            );
            await loadFiles();
          }
          await loadFiles();
        },
      ),
    );
  }

  Card renderFile(FileStoreElement file, String roomFingerprint) {
    return Card(
      color:
          file.isDeleted ? Theme.of(context).colorScheme.errorContainer : null,
      child: ListTile(
        leading: const Icon(Icons.description),
        title: Text(
          p.basename(file.path),
          maxLines: 1,
        ),
        subtitle:
            Text('${(file.sizeBytes / 1024 / 1024).toStringAsFixed(4)} MiB'),
        onLongPress: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FileView(
                file: file,
                roomFingerprint: roomFingerprint,
              ),
            ),
          );
          await loadFiles();
        },
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return switch (file.path.split('.').reversed.first) {
                  'xdc' => WebxdcFileView(
                      file: file,
                      roomFingerprint: roomFingerprint,
                      chatroom: chatroom,
                    ),
                  _ => FileView(
                      file: file,
                      roomFingerprint: roomFingerprint,
                    )
                };
              },
            ),
          );
          await loadFiles();
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
