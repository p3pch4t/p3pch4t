// ignore_for_file: use_if_null_to_convert_nulls_to_bools

import 'dart:async';
import 'dart:io';

import 'package:dart_pg/dart_pg.dart' as pgp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/home.dart';
import 'package:p3pch4t/service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ...userInfoFields(),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ...reachableSelect(),
                ],
              ),
            ),

            const Divider(),
            // key size (4096, 2048, 1024)
            // how to contact?
            //  - reachableLocal (only if kDebugMode)
            //  - reachableRelay (if yes which relays)
            //  - reachableI2p (if yes)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'You may want to change the key size used by the app when you '
                'are running on a older device.\n'
                'It is recommended to leave this settings on default.',
              ),
            ),
            ...keySizeSelect(),
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: (usernameCtrl.text == '' || emailCtrl.text == '')
            ? null
            : () async {
                unawaited(
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return Container(
                        color: Colors.grey,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 222));
                final prefs = await SharedPreferences.getInstance();

                debugPrint('generating privkey...');
                final privkey = await pgp.OpenPGP.generateKey(
                  ['${usernameCtrl.text} <${emailCtrl.text}>'],
                  'no_passpharse',
                );
                await prefs.setString('priv_key', privkey.armor());
                if (Platform.isAndroid || Platform.isIOS) {
                  await Permission.notification.request();
                }
                await initializeService();
                final selfUser = await p3p!.getSelfInfo();
                selfUser.endpoint = [
                  if (localEnabled) ...ReachableLocal.getDefaultEndpoints(p3p!),
                  if (relayEnabled) ...ReachableRelay.getDefaultEndpoints(p3p!),
                  if (i2pEnabled) ...ReachableI2p.getDefaultEndpoints(p3p!),
                ];
                await prefs.setBool('reachable.local', localEnabled);
                await prefs.setBool('reachable.relay', relayEnabled);
                await prefs.setBool('reachable.i2p', i2pEnabled);
                selfUser.name = usernameCtrl.text;
                final publicKey = await PublicKey.create(
                  p3p!,
                  p3p!.privateKey.toPublic.armor(),
                );
                publicKey!.id = await p3p!.db.save(publicKey);
                selfUser.publicKey = publicKey;
                selfUser.id = await p3p!.db.save(selfUser);
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 222));
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
        child: const Text('Register'),
      ),
    );
  }

  bool localEnabled = true;
  bool relayEnabled = true;
  bool i2pEnabled = false;

  List<Widget> reachableSelect() {
    return [
      if (kDebugMode)
        CheckboxListTile(
          value: localEnabled,
          onChanged: (val) => setState(() {
            localEnabled = val == true;
            if (i2pEnabled == true && val == false) {
              i2pEnabled = false;
            }
          }),
          title: const Text('Local Enabled'),
          subtitle: const Text(
            'Local is required for i2p transport and local-network connections',
          ),
        ),
      CheckboxListTile(
        value: relayEnabled,
        onChanged: (val) => setState(() {
          relayEnabled = val == true;
        }),
        title: const Text('Relay Transport (recommended)'),
        subtitle: const Text(
          'Relay uses federated servers to deliver messages to recipents',
        ),
      ),
      CheckboxListTile(
        value: i2pEnabled,
        onChanged: (val) => setState(() {
          i2pEnabled = val == true;
          if (localEnabled == false && val == true) {
            localEnabled = true;
          }
        }),
        title: const Text('P2P i2p transport'),
        subtitle: const Text(
          'Use i2p peer-to-peer network to contact other peers it may increase '
          'battery usage significantly.',
        ),
      ),
    ];
  }

  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController(text: 'user@example.com');

  List<Widget> userInfoFields() {
    return [
      TextField(
        controller: usernameCtrl,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          label: Text('Username'),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: emailCtrl,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          label: Text('E-Mail'),
          border: OutlineInputBorder(),
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'E-Mail is only needed to generate the key, feel free to leave the '
          'default email, or input your own - there is no verification of '
          'email addresses implemented at all.\n\n'
          'There is no password  instead we will generate a private key that '
          'will be used to encrypt all messages.',
        ),
      ),
    ];
  }

  pgp.RSAKeySize keySize = pgp.RSAKeySize.s4096;

  List<Widget> keySizeSelect() {
    return [
      ListTile(
        title: const Text('4096 bit (recommended)'),
        leading: Radio<pgp.RSAKeySize>(
          value: pgp.RSAKeySize.s4096,
          groupValue: keySize,
          onChanged: (pgp.RSAKeySize? value) {
            if (value != null) {
              setState(() {
                keySize = value;
              });
            }
          },
        ),
      ),
      if (kDebugMode)
        ListTile(
          title: const Text('3584 bit [debug]'),
          leading: Radio<pgp.RSAKeySize>(
            value: pgp.RSAKeySize.s3584,
            groupValue: keySize,
            onChanged: (pgp.RSAKeySize? value) {
              if (value != null) {
                setState(() {
                  keySize = value;
                });
              }
            },
          ),
        ),
      if (kDebugMode)
        ListTile(
          title: const Text('3072 bit [debug]'),
          leading: Radio<pgp.RSAKeySize>(
            value: pgp.RSAKeySize.s3072,
            groupValue: keySize,
            onChanged: (pgp.RSAKeySize? value) {
              if (value != null) {
                setState(() {
                  keySize = value;
                });
              }
            },
          ),
        ),
      if (kDebugMode)
        ListTile(
          title: const Text('2560 bit [debug]'),
          leading: Radio<pgp.RSAKeySize>(
            value: pgp.RSAKeySize.s2560,
            groupValue: keySize,
            onChanged: (pgp.RSAKeySize? value) {
              if (value != null) {
                setState(() {
                  keySize = value;
                });
              }
            },
          ),
        ),
      ListTile(
        title: const Text('2048 bit (for slow devices)'),
        leading: Radio<pgp.RSAKeySize>(
          value: pgp.RSAKeySize.s2048,
          groupValue: keySize,
          onChanged: (pgp.RSAKeySize? value) {
            if (value != null) {
              setState(() {
                keySize = value;
              });
            }
          },
        ),
      ),
    ];
  }
}

// setState(() {
//   isLoading = true;
// });
// final prefs = await SharedPreferences.getInstance();

// debugPrint('generating privkey...');
// final privkey = await OpenPGP.generateKey(
//   ['name <user@example.org>'],
//   'no_passpharse',
// );
// await prefs.setString('priv_key', privkey.armor());
// setState(() {
//   isLoading = false;
// });
// if (!mounted) {
//   await Future<void>.delayed(const Duration(seconds: 1));
//   exit(1);
// }
// if (Platform.isAndroid) {
//   await Permission.notification.request();
// }
// await initializeService();
// if (mounted) return;
