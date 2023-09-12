// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/consts.dart';
import 'package:p3pch4t/pages/home.dart';
import 'package:p3pch4t/pages/landing.dart';
import 'package:p3pch4t/service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The globaly-used p3p object for the chat app.
P3p? p3p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('priv_key') == null) {
    runApp(const MyApp(landing: true));
    return;
  }
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }
  await initializeService();
  runApp(const MyApp(landing: false));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.landing, super.key});
  final bool landing;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P3pCh4t $P3PCH4T_VERSION',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: landing ? const LandingPage() : const HomePage(),
    );
  }
}
