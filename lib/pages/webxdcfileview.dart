// ignore_for_file: public_member_api_docs

import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/fileview.dart';
import 'package:p3pch4t/pages/webxdcfileview_android.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

const csp =
    "default-src 'self'; style-src 'self' 'unsafe-inline' blob: ; font-src 'self' data: blob: ; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob: ; connect-src 'self' data: blob: ; img-src 'self' data: blob: ; media-src 'self' data: blob: ;webrtc 'block' ; "; // ignore: lines_longer_than_80_chars

class WebxdcFileView extends StatefulWidget {
  const WebxdcFileView({
    required this.file,
    required this.roomFingerprint,
    required this.chatroom,
    super.key,
  });

  final FileStoreElement file;
  final String roomFingerprint;
  final UserInfo chatroom;

  @override
  State<WebxdcFileView> createState() => _WebxdcFileViewState();
}

class _WebxdcFileViewState extends State<WebxdcFileView> {
  late final file = widget.file;
  late final roomFingerprint = widget.roomFingerprint;
  late final chatroom = widget.chatroom;
  late final HttpServer server;
  late final Archive archive;

  double? progress;

  @override
  void initState() {
    try {
      startLocalServer();
    } catch (e) {
      p3p.print('[webxdc] startLocalServer: $e');
    }
    super.initState();
  }

  @override
  void dispose() {
    try {
      server.close();
    } catch (e) {
      p3p.print('[webxdc] server.close(): $e');
    }

    super.dispose();
  }

  void updateProgress(double? value) {
    setState(() {
      progress = value;
    });
  }

  Future<void> startLocalServer() async {
    updateProgress(0.1);
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_processRequest);

    server = await shelf_io.serve(
      handler,
      'localhost',
      12121 + Random().nextInt(2000),
    );

    updateProgress(0.2);

    final inputStream = InputFileStream(file.localPath);
    archive = ZipDecoder().decodeBuffer(inputStream);
    updateProgress(1);
  }

  Future<Response> _processRequest(Request request) async {
    var path = request.url.path;
    if (path == '') path = 'index.html';
    switch (path) {
      case 'webxdc.js' || '/webxdc.js':
        final si = p3p.getSelfInfo();
        return Response.ok(
          '''
console.log("[webxdc.js]: loaded native implementation on browser side");

window.webxdc = {
  sendUpdate: function (update, descr) {
    p3p_native_sendUpdate.postMessage(JSON.stringify({
      "update": update,
      "descr": descr,
    }));
  },
  setUpdateListener: async function(update, serial) {
    let listId = window.webxdc.setUpdateListenerList.push(update)
    p3p_native_setUpdateListener.postMessage(JSON.stringify({
      "listId": listId,
      "serial": serial,
    }));
    // await window.webxdc.sleep(250);
    return;
  },
  sendToChat: function (message) {
    p3p_native_sendToChat(JSON.stringify(message));
  },
  importFiles: function (filter) {}, // TODO: implement
  selfAddr: `${si.publicKey.armored /* TODO: make this code atob btoa */}`,
  selfName: `${si.name}`,
  // END OF OFFICIAL IMPLEMENTATION, p3p extensions below

  // END OF IMPLEMENTATION, internal use below
  setUpdateListenerList: [],
  sleep: (delay) => new Promise((resolve) => setTimeout(resolve, delay))
}
''',
          headers: {'Content-Type': 'application/javascript'},
        );
      case '__debuginfo' || '/__debuginfo':
        return Response.ok(
          '''
<a href="/webxdc.js">webxdc.js</a><br />
''',
          headers: {
            'Content-Type': 'text/html',
          },
        );
    }
    for (final file in archive.files) {
      if (file.name == path) {
        final data = file.content; // !.readBytes(file.size).toUint8List();

        return Response.ok(
          data,
          headers: {
            'Content-Type': lookupMimeType(path) ?? 'application/octet-stream',
            'Content-Security-Policy': csp,
          },
        );
      }
    }
    return Response.ok('requiest for $path');
  }

  @override
  Widget build(BuildContext context) {
    if (progress != 1) {
      return Scaffold(
        appBar: AppBar(),
        body: LinearProgressIndicator(value: progress),
      );
    }
    if (file.downloadedSizeBytes != file.sizeBytes ||
        file.downloadedSizeBytes == 0) {
      return FileView(
        file: file,
        roomFingerprint: roomFingerprint,
      );
    }
    if (Platform.isAndroid) {
      return WebxdcFileViewAndroid(
        startUrl: 'http://localhost:${server.port}/',
        allowOnly: 'http://localhost:${server.port}',
        chatroom: chatroom,
        webxdcFile: file,
      );
    }
    return Scaffold(
      appBar: AppBar(),
      body: const Text('WebXDC is not yet supported on this platform'),
    );
  }
}
