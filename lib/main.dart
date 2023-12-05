// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i2p/flutter_i2p.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/consts.dart';
import 'package:p3pch4t/pages/home.dart';
import 'package:p3pch4t/pages/landing.dart';
import 'package:p3pch4t/platform_interface.dart';
import 'package:p3pch4t/service.dart';
import 'package:p3pch4t/switch_platform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// The globaly-used p3p object for the chat app.
late P3p p3p; // = getP3p(null); // use auto-detect path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getAndroidNativeLibraryDirectory(forceRefresh: true);
  p3p = switch (getPlatform()) {
    OS.android => await getP3p(
        p.join(
          (await getAndroidNativeLibraryDirectory()).path,
          'libp3pgo.so',
        ),
      ),
    OS.linux => await getP3p(
        File('/home/user/go/src/git.mrcyjanek.net/p3pch4t/p3pgo/build/api_host.so')
                .existsSync()
            ? '/home/user/go/src/git.mrcyjanek.net/p3pch4t/p3pgo/build/api_host.so'
            : 'lib/libp3pgo.so',
      ),
    _ => throw UnimplementedError()
  };
  final dirPath = p.join(
    (await getApplicationDocumentsDirectory()).path,
    '.p3pch4t',
  );
  p3p.initStore(dirPath, '', '');
  if (p3p.showSetup()) {
    runApp(
      MyApp(
        w: await I2pdEnsure.checkAndRun(
          app: const LandingPage(),
          binPath: await getBinPath(),
        ),
      ),
    );
    return;
  }
  await softStartI2p();
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }
  // await initializeService();
  runApp(
    MyApp(
      w: await I2pdEnsure.checkAndRun(
        app: const HomePage(),
        binPath: await getBinPath(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({required this.w, super.key});
  final Widget w;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P3pCh4t $P3PCH4T_VERSION',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: w,
    );
  }
}

Future<void> softStartI2p() async {
  await startI2p();
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    p3p.setPrivateInfoEepsiteDomain(
      (await i2p!.domainInfo('p3pch4tmain.dat'))!,
    );
    timer.cancel();
  });
}
