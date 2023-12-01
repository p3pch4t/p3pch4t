// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart' as dio;
import 'package:p3pch4t/consts.dart';
import 'package:p3pch4t/service.dart';
import 'package:p3pch4t/switch_platform.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionWidget extends StatefulWidget {
  const VersionWidget({
    super.key,
  });

  @override
  State<VersionWidget> createState() => _VersionWidgetState();
}

bool isFirstTime = true;

class _VersionWidgetState extends State<VersionWidget> {
  String? infoString;
  String? extraInfo;
  late Color color = Theme.of(context).cardColor;

  bool showRefresh = false;

  @override
  void initState() {
    loadVersion();
    super.initState();
  }

  Future<void> loadVersion() async {
    if (kDebugMode) {
      setState(() {
        infoString = 'Debug mode detected';
        extraInfo = 'You are running a debug build, and you probably know the '
            'consequences - namely more logging, bigger app size, higher app '
            'requirements - generally all the things that you would prefer to '
            'avoid when using the app - so once you finish working on the app '
            'please, use the official build.';
      });
      return;
    }

    if (isFirstTime) {
      isFirstTime = false;
      await Future<void>.delayed(const Duration(seconds: 30));
    }

    if (P3PCH4T_VERSION.contains('-dirty')) {
      final gitChanges = await rootBundle.loadString('assets/git-changes.md');
      setState(() {
        infoString = 'Running a dirty build';
        extraInfo = 'You are running a _dirty_ build, which means that '
            'somebody handed you the app to test some feature.\n\n'
            'However - it is not recommended to use this kind of builds unless '
            'you are the person who have created these changes (and even then '
            'you probably should push the changes upstream)\n\n'
            'B.. b.. but i have some *cool* awesome feature that is not in the '
            'mainline release. Well... But you may break the network by using '
            'the forked version.\n\n\n'
            '--------\n\n$gitChanges';
        color = Theme.of(context).colorScheme.errorContainer;
      });
      return;
    }

    try {
      final version = await i2p!.dio!.get<String>(
        '$STATIC_MRCYJANEK_NET_I2P/p3pch4t/latest/version.txt',
      );
      //'https://static.mrcyjanek.net/p3pch4t/latest/version.txt'),

      if (version.data?.trim() == P3PCH4T_VERSION.trim()) {
        return; // oki - we are on correct version
      }
      setState(
        () {
          infoString = 'New version if available!';
          extraInfo =
              'New version is available: **${version.data?.trim()}**. You are '
              ' currently running on: **${P3PCH4T_VERSION.trim()}**\nIt is '
              'important to use latest version to ensure network stability. '
              '(Especially during beta) .';
        },
      );
    } catch (e) {
      setState(() {
        infoString = 'Unable to fetch update details';
        extraInfo = 'There are 2 options\n'
            "1. You are offline and we can't reach our update servers\n"
            "2. The app was updated many times and you weren't online "
            'and as a consequence update server got migrated. In that case '
            'you chould use the button below to update\n'
            '\n\n---- error ----\n\n$e';
        showRefresh = true;
        color = Theme.of(context).colorScheme.errorContainer;
      });
    }
  }

  void _showExtraDialog() {
    assert(infoString != null, 'infoString is null!');
    assert(extraInfo != null, 'extraInfo is null');
    // ignore: inference_failure_on_function_invocation
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(infoString!),
          content: SingleChildScrollView(
            child: Text(extraInfo!),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (infoString == null) return Container();
    return Card(
      color: color,
      child: ListTile(
        title: Text(infoString!),
        leading: extraInfo == null
            ? null
            : IconButton(
                onPressed: _showExtraDialog,
                icon: const Icon(Icons.info),
              ),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showRefresh)
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton(
                  onPressed: () {
                    loadVersion();
                    setState(() {
                      infoString = null;
                      extraInfo = null;
                      showRefresh = false;
                    });
                  },
                  child: const Text('Try again'),
                ),
              ),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      'https://static.mrcyjanek.net/p3pch4t/latest/p3pch4t-release/${switch (getPlatform()) {
                        OS.android => "android",
                        OS.linux => "linux",
                        _ => "",
                      }}',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('Update (static.mrcyjanek.net)'),
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      '$STATIC_MRCYJANEK_NET_I2P/p3pch4t/latest/p3pch4t-release/${switch (getPlatform()) {
                        OS.android => "android",
                        OS.linux => "linux",
                        _ => "",
                      }}',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('Update (i2p mirror)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
