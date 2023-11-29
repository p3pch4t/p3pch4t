// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

class WebxdcFileViewAndroid extends StatefulWidget {
  const WebxdcFileViewAndroid({
    required this.startUrl,
    required this.allowOnly,
    required this.chatroom,
    required this.webxdcFile,
    super.key,
  });

  final String startUrl;
  final String allowOnly;
  final UserInfo chatroom;
  final FileStoreElement webxdcFile;

  @override
  State<WebxdcFileViewAndroid> createState() => _WebxdcFileViewAndroidState();
}

class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
  double? progress;

  late final fileStore = widget.chatroom.fileStore;
  late final roomFingerprint = widget.chatroom.publicKey.fingerprint;
  late final controller = WebViewController();

  @override
  void initState() {
    loadController();
    super.initState();
  }

  Future<void> loadController() async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0x00000000));
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int newProgress) {
          setState(() {
            progress = 100 / newProgress;
          });
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith(widget.allowOnly)) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ),
    );
    await controller.addJavaScriptChannel(
      'p3p_native_sendUpdate',
      onMessageReceived: (p0) async {
        // I/flutter (14004): {
        // I/flutter (14004):     "update": {
        // I/flutter (14004):         "payload": {
        // I/flutter (14004):             "addr": "-----BEGIN PGP PUBLIC KEY BLOCK-----",
        // I/flutter (14004):             "name": "localuser",
        // I/flutter (14004):             "score": 25
        // I/flutter (14004):         },
        // I/flutter (14004):         "summary": "Top builder is localuser",
        // I/flutter (14004):         "info": "localuser scored 25 in Tower Builder!"
        // I/flutter (14004):     },
        // I/flutter (14004):     "descr": "localuser scored 25 in Tower Builder!"
        // I/flutter (14004): }
        if (kDebugMode) print('p3p_native_sendUpdate:');
        // p0.message is what we receive from the browser
        final jBody = json.decode(p0.message) as Map<String, dynamic>;
        // what is interesting for us is the "update" field, as can be seen in
        // comment above.
        final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
        // 'info' field, according to WebXDC field should be sent to the room.
        if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
          p3p.sendMessage(
            widget.chatroom,
            jBodyUpdate['info'].toString(),
            type: MessageType.service,
          );
        }
        // append the update to update file.
        final updateElm = getUpdateElement();
        if (updateElm == null) {
          // We don't have the .jsonp file - despite the fact that it was
          // created.
          if (mounted) Navigator.of(context).pop();
          return;
        }

        // For whatever reason I'd love to use microseconds, because idk
        // but I can't because JS.
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        updateElm.file.writeAsStringSync(
          "\n$timestamp:${json.encode(jBodyUpdate["payload"])}",
          mode: FileMode.append,
          flush: true,
        );

        updateElm.updateFileContent();
        final jsPayload = '''
for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
  window.webxdc.setUpdateListenerList[i]({
    // NOTE: Is it possible to exploit this somehow?
    // talking about the dart side of things.
    // UPDATE: talking about go part of things too
    // I don't really care if it get's exploited in browser.
    // I mean I do but it doesn't matter imo.
    // I'm sorry for you if you had to dig here from JS world.
    "payload": ${json.encode(jBodyUpdate["payload"])},
    "serial": $timestamp,
    "max_serial": $timestamp,
    "info": null,
    "document": null,
    "summary": null,
  })
}
''';
        if (kDebugMode) print(jsPayload);
        await controller.runJavaScript(jsPayload);
      },
    );
    await controller.addJavaScriptChannel(
      'p3p_native_sendToChat',
      onMessageReceived: (p0) {
        if (kDebugMode) print('p3p_native_sendToChat: ${p0.message}');
      },
    );
    await controller.addJavaScriptChannel(
      'p3p_native_setUpdateListener',
      onMessageReceived: (p0) async {
        // {
        //   "listId": listId,
        //   "serial": serial,
        // }
        final jBody = json.decode(p0.message) as Map<String, dynamic>;
        assert(jBody['listId'] is int, 'ListID is not a string');
        if (kDebugMode) print('p3p_native_setUpdateListener: ${p0.message}');
        final updateElm = getUpdateElement();
        if (updateElm == null) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        if (!updateElm.file.existsSync()) {
          print("file doesn't exist.");
          updateElm.file.createSync(recursive: true);
        }
        if (updateElm.file.lengthSync() == 0) {
          print('length is 0');
          return;
        }
        p3p.print('updateElm.file.length: ${updateElm.file.lengthSync()}');
        final lines = updateElm.file.readAsLinesSync();
        var maxInt = 1;
        for (final lineReversed in lines.reversed) {
          final colonIndex = lineReversed.indexOf(':');
          if (colonIndex == -1) continue;
          final index = int.tryParse(lineReversed.substring(0, colonIndex));
          if (index == null) continue;

          maxInt = max(index, maxInt);
        }
        for (var i = 0; i < lines.length; i++) {
          final colonIndex = lines[i].indexOf(':');
          if (colonIndex == -1) continue;
          final matchInt = int.tryParse(lines[i].substring(0, colonIndex));
          if (matchInt == null) continue;
          try {
            final payload =
                json.encode(json.decode(lines[i].substring(colonIndex + 1)));
            final jsPayload = '''
console.log("setUpdateListener: hook id: $i");

window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
  "payload": $payload,
  "serial": $matchInt,
  "max_serial": $maxInt,
  "info": null,
  "document": null,
  "summary": null,
})
''';
            if (kDebugMode) print(jsPayload);
            await controller.runJavaScript(jsPayload);
          } catch (e) {
            if (kDebugMode) {
              print('failed to process event: $i');
              print(e);
            }
            continue;
          }
        }
      },
    );
    await controller.loadRequest(Uri.parse(widget.startUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kDebugMode
          ? AppBar(
              actions: [
                navigateActionButton(widget.startUrl, Icons.home),
                navigateActionButton(
                  '${widget.startUrl}/__debuginfo',
                  Icons.bug_report,
                ),
                IconButton(
                  onPressed: () {
                    controller.reload();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }

  IconButton navigateActionButton(String url, IconData icon) {
    return IconButton(
      onPressed: () {
        controller.loadRequest(Uri.parse(url));
      },
      icon: Icon(icon),
    );
  }

  FileStoreElement? getUpdateElement() {
    final elms = widget.chatroom.fileStore
        .files; //await widget.chatroom.fileStore.getFileStoreElement(p3p!);
    final wpath = widget.webxdcFile.path;
    final desiredPath = p.normalize(
      (wpath.split(Platform.isWindows ? r'\' : '/')
            ..removeLast()
            ..add('.${p.basename(wpath)}.update.jsonp'))
          .join('/'),
    );
    FileStoreElement? updateElm;
    for (final felm in elms) {
      if (felm.path == desiredPath && !felm.isDeleted) {
        updateElm = felm;
      }
    }
    if (updateElm == null) {
      return p3p.createFileStoreElement(
        widget.chatroom,
        localFilePath: '',
        fileInChatPath: desiredPath,
      );
    }
    return updateElm;
  }
}
