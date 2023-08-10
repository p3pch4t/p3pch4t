import 'dart:io';

import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/pages/home.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

late final P3p p3p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (prefs.getString("priv_key") == null) {
    debugPrint("generating privkey...");
    final privkey = await OpenPGP.generateKey(
        ['name <user@example.org>'], 'no_passpharse',
        rsaKeySize: RSAKeySize.s4096);
    prefs.setString("priv_key", privkey.armor());
  }
  debugPrint("starting p3p...");

  p3p = await P3p.createSession(
    p.join(appDocumentsDir.path, "p3pch4t"),
    prefs.getString("priv_key")!,
    "no_passpharse",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P3pCh4t',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
