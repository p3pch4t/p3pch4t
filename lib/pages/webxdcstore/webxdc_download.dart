import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p3pch4t/pages/webxdcstore/data_model.dart';
import 'package:p3pch4t/pages/webxdcstore/home.dart';
import 'package:p3pch4t/pages/webxdcstore/webxdc_dl.dart';
import 'package:p3pch4t/pages/widgets/cachednetworkimage.dart';

class WebXDCDownloadPage extends StatelessWidget {
  const WebXDCDownloadPage({required this.app, super.key});

  final WebXDCApp app;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(app.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 1,
              child: SizedBox(
                width: double.maxFinite,
                child:
                    I2pCachedNetworkImage(imageUrl: '$storeurl/${app.banner}'),
              ),
            ),
            ...buildReleaseTiles(context),
          ],
        ),
      ),
    );
  }

  List<Widget> buildReleaseTiles(BuildContext context) {
    final lt = <Widget>[];
    final keys = app.releases.keys.toList();
    keys.sort();

    for (final key in keys.reversed) {
      if (!app.supportedRelease.contains(key)) continue;
      lt.add(
        ListTile(
          title: Text(key),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(app.shortDescription),
              SizedBox(
                width: double.maxFinite,
                child: WebXDCDownloadWidget(
                  app: app,
                  releaseKey: key,
                ),
              ),
            ],
          ),
        ),
      );
    }
    lt.add(const Divider());
    for (final key in keys.reversed) {
      if (app.supportedRelease.contains(key)) continue;
      lt.add(
        ExpansionTile(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          collapsedBackgroundColor:
              Theme.of(context).colorScheme.errorContainer,
          title: Text(key),
          childrenPadding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "This is an unsupported release, which has reached it's end "
                'of life period. It is not recommended to use this version.\n',
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: WebXDCDownloadWidget(
                app: app,
                releaseKey: key,
              ),
            ),
          ],
        ),
      );
    }
    return lt;
  }
}

class WebXDCDownloadWidget extends StatefulWidget {
  const WebXDCDownloadWidget({
    required this.app,
    required this.releaseKey,
    super.key,
  });

  final String releaseKey;
  final WebXDCApp app;

  @override
  State<WebXDCDownloadWidget> createState() => _WebXDCDownloadWidgetState();
}

class _WebXDCDownloadWidgetState extends State<WebXDCDownloadWidget> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await download(context, widget.app, widget.releaseKey);
        refresh();
      },
      child: !isDownloaded ? const Text('Download') : const Text('re-Download'),
    );
  }

  @override
  void initState() {
    refresh();
    super.initState();
  }

  void refresh() {
    getWebXDCFile(widget.app, widget.releaseKey).then((f) {
      setState(() {
        isDownloaded = f.existsSync();
      });
    });
  }

  bool isDownloaded = false;
}

Future<void> download(BuildContext context, WebXDCApp app, String key) async {
  final alert = AlertDialog(
    content: Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircularProgressIndicator(),
        ),
        Expanded(
          child: Text('Installing ${app.name} $key [${app.uniqueId}]'),
        ),
      ],
    ),
  );
  unawaited(
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    ),
  );
  try {
    await downloadWebXDC(app, key);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    final crashAlert = AlertDialog(
      title: const Text('Failed to download app'),
      content: SelectableText(e.toString()),
    );
    if (!context.mounted) return;
    unawaited(
      showDialog(
        context: context,
        builder: (BuildContext context) => crashAlert,
      ),
    );
    return;
  }
  if (!context.mounted) return;
  Navigator.of(context).pop();
  const crashAlert = AlertDialog(
    title: Text('App installed!'),
    content: SelectableText('You can now use the app directly from your chats'),
  );
  await Future<void>.delayed(const Duration(microseconds: 123));
  if (!context.mounted) return;
  unawaited(
    showDialog(
      context: context,
      builder: (BuildContext context) => crashAlert,
    ),
  );
}
