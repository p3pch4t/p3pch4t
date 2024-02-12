// ignore_for_file: public_member_api_docs

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/fileview_sharedfile.dart';

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

  Iterable<SharedFile> files = [];
  String path = '/';

  @override
  void initState() {
    loadFiles();
    super.initState();
  }

  void loadFiles() {
    final newFiles = chatroom.sharedFiles.files;
    setState(() {
      files = newFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inScopeAll =
        files.where((elm) => elm.filePath.startsWith(path)).toList();
    var inScopeDirectories = <String>[];
    if (path != '/') {
      inScopeDirectories.add('..');
    }
    for (final file in inScopeAll) {
      if (file.filePath == p.join(path, p.basename(file.filePath))) continue;

      var fs1 = file.filePath.substring(path.length);
      if (fs1.startsWith('/')) fs1 = fs1.substring(1);

      inScopeDirectories.add(fs1.substring(0, fs1.indexOf('/')));
    }
    inScopeDirectories = inScopeDirectories.toSet().toList();
    final inScopeFiles = inScopeAll
        .where((elm) => !elm.filePath.substring(path.length + 1).contains('/'))
        .where((elm) => kDebugMode || !p.basename(elm.filePath).startsWith('.'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        child: const Icon(Icons.upload),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles();
          if (result == null) return;
          if (result.files.isEmpty) return;
          for (final file in result.files) {
            final today = DateTime.now();
            final dateSlug = '${today.year}-'
                '${today.month.toString().padLeft(2, '0')}-'
                '${today.day.toString().padLeft(2, '0')}';
            final ret = p3p.createSharedFile(
              chatroom,
              localFilePath: file.path!,
              remoteFilePath: '/Unsort/$dateSlug/${file.name}',
            );
            if (ret != null) {
              p3p.print(ret);
            }
            loadFiles();
          }
          loadFiles();
        },
      ),
    );
  }

  Card renderFile(SharedFile file, String roomFingerprint) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description),
        title: Text(
          p.basename(file.filePath),
          maxLines: 1,
        ),
        subtitle:
            Text('${(file.sizeBytes / 1024 / 1024).toStringAsFixed(4)} MiB'),
        onLongPress: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => FileView(
                file: file,
                roomFingerprint: roomFingerprint,
              ),
            ),
          );
          loadFiles();
        },
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) {
                return FileView(
                  file: file,
                  roomFingerprint: roomFingerprint,
                );
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
