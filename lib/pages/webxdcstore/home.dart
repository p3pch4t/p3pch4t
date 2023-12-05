// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/consts.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/webxdcstore/data_model.dart';
import 'package:p3pch4t/pages/webxdcstore/details_page.dart';
import 'package:p3pch4t/pages/widgets/cachednetworkimage.dart';
import 'package:p3pch4t/service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const storeurl = '$STATIC_MRCYJANEK_NET_I2P/webxdc';

class WebXDCStore extends StatefulWidget {
  const WebXDCStore({super.key});

  @override
  State<WebXDCStore> createState() => _WebXDCStoreState();
}

class _WebXDCStoreState extends State<WebXDCStore> {
  WebXDCStoreMetaJSON? store;
  @override
  void initState() {
    loadData();
    super.initState();
  }

  Future<void> loadData() async {
    final cache = await getApplicationCacheDirectory();
    cache.createSync();
    final cachedJsonFile =
        File(p.join(cache.absolute.path, 'store-latest.json'));
    if (cachedJsonFile.existsSync()) {
      setState(() {
        store = WebXDCStoreMetaJSON.fromJson(
          json.decode(cachedJsonFile.readAsStringSync())
              as Map<String, dynamic>,
        );
      });
      if (DateTime.now()
          .subtract(const Duration(hours: 24))
          .isBefore(cachedJsonFile.lastModifiedSync())) {
        return;
      }
      p3p.print('refreshing file');
      await refreshData(cachedJsonFile.path);
      return;
    }
    await refreshData(cachedJsonFile.path);
  }

  String? error;

  Future<void> refreshData(String savePath) async {
    p3p.print('refreshData: downloading');
    try {
      await i2p!.dio!.download('$storeurl/meta.json', savePath);
      File(savePath).setLastModifiedSync(DateTime.now());
    } catch (e) {
      setState(() {
        error = e.toString();
      });
      return;
    }
    p3p.print('refreshData: downloading done');
    setState(() {
      store = WebXDCStoreMetaJSON.fromJson(
        json.decode(File(savePath).readAsStringSync()) as Map<String, dynamic>,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('WebXDC store'),
        ),
        body: Stack(
          children: [
            if (error == null) const LinearProgressIndicator(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: SelectableText(
                  error ?? '',
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: store == null
            ? null
            : ElevatedButton(
                onPressed: () {
                  setState(() {
                    error = null;
                  });
                },
                child: const Text('Load cached version.'),
              ),
      );
    }
    if (store == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('WebXDC store'),
        ),
        body: const Stack(
          children: [
            LinearProgressIndicator(),
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Downloading new store metadata from $STATIC_MRCYJANEK_NET_I2P\n'
                  'This may take a couple of seconds.',
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(kDebugMode ? 'WebXDC app store' : 'App Store'),
      ),
      body: ListView.builder(
        itemCount: store!.apps.keys.length,
        itemBuilder: (context, index) {
          return WebXDCAppWidget(
            app: store!.apps[store!.apps.keys.toList()[index]]!,
          );
        },
      ),
    );
  }
}

class WebXDCAppWidget extends StatelessWidget {
  const WebXDCAppWidget({
    required this.app,
    super.key,
  });

  final WebXDCApp app;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => WebXDCDetailsPage(app: app),
          ),
        );
      },
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 2 / 1,
              child: SizedBox(
                width: double.maxFinite,
                child:
                    I2pCachedNetworkImage(imageUrl: '$storeurl/${app.banner}'),
              ),
            ),
            ListTile(
              title: Text(
                app.name,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 26,
                      overflow: TextOverflow.ellipsis,
                    ),
                maxLines: 1,
              ),
              contentPadding: const EdgeInsets.all(4),
              subtitle: Column(
                children: [
                  Text(
                    app.shortDescription,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //SizedBox(height: 4),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   children: [
                  //     Text(
                  //       'by ${app.author}',
                  //       maxLines: 1,
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
