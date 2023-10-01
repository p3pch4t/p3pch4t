// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/helpers.dart';
import 'package:p3pch4t/pages/home.dart';
import 'package:p3pch4t/pages/register.dart';
import 'package:p3pch4t/service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const LoadingPlaceholder();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to p3pch4t!'),
      ),
      body: Column(
        children: [
          const Text('Welcome to p3pch4t.'),
          const Text('Do you have an account? If yes '
              'press restore below, otherwise Register'),
          const Spacer(),
          const Divider(),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: const Text('Restore'),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  // it is used safely here.
                  // ignore: use_build_context_synchronously
                  await Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final privateKeyCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          Expanded(
            child: TextField(
              controller: privateKeyCtrl,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Your private key',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          TextField(
            controller: passwordCtrl,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Your private key password',
              border: OutlineInputBorder(),
            ),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    try {
                      setState(() {
                        isLoading = true;
                      });
                      final prefs = await SharedPreferences.getInstance();

                      debugPrint('loading privkey...');
                      final privkey =
                          await OpenPGP.readPrivateKey(privateKeyCtrl.text);
                      await prefs.setString('priv_key', privkey.armor());
                      await prefs.setString(
                        'priv_passpharse',
                        passwordCtrl.text,
                      );
                      setState(() {
                        isLoading = false;
                      });
                      await initializeService();
                      if (!mounted) {
                        await Future<void>.delayed(const Duration(seconds: 1));
                        exit(1);
                      }

                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        privateKeyCtrl.text =
                            'Failed to restore session please make sure that '
                            'the private key is valid.'
                            '\n\n---- error ----\n\n$e';
                      });
                    }
                  },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
