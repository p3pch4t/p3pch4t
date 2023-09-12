// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:io';

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
        final jBody = json.decode(p0.message) as Map<String, dynamic>;
        final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
        if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
          await p3p!.sendMessage(
            widget.chatroom,
            jBodyUpdate['info'].toString(),
            type: MessageType.service,
          );
        }
        // append the update to update file.
        final updateElm = await getUpdateElement();
        if (updateElm == null) {
          if (mounted) Navigator.of(context).pop();
          return;
        }

        await updateElm.file.writeAsString(
          "\n${json.encode(jBodyUpdate["payload"])}",
          mode: FileMode.append,
          flush: true,
        );
        final lines = await updateElm.file.readAsLines();
        await updateElm.updateContent(
          p3p!,
        );
        final jsPayload = '''
for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
  window.webxdc.setUpdateListenerList[i]({
    "payload": ${json.encode(jBodyUpdate["payload"])},
    "serial": ${lines.length},
    "max_serial": ${lines.length},
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
        final updateElm = await getUpdateElement();
        if (updateElm == null) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        final lines = updateElm.file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          try {
            final payload = json.encode(json.decode(lines[i]));
            final jsPayload = '''
console.log("setUpdateListener: hook id: $i");

window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
  "payload": $payload,
  "serial": $i,
  "max_serial": ${lines.length},
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

  Future<FileStoreElement?> getUpdateElement() async {
    final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
    final wpath = widget.webxdcFile.path;
    final desiredPath = p.normalize(
      (wpath.split('/')
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
      updateElm = await widget.chatroom.fileStore.putFileStoreElement(
        p3p!,
        localFile: null,
        localFileSha512sum: null,
        sizeBytes: 0,
        fileInChatPath: desiredPath,
        uuid: null,
      )
        ..shouldFetch = true;
      await updateElm.updateContent(p3p!);

      return updateElm;
    }
    return updateElm;
  }
}
