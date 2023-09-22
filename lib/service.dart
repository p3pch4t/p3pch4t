// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:dart_i2p/dart_i2p.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:p3p/p3p.dart';
// ignore: implementation_imports
import 'package:p3p/src/database/drift.dart' as db;
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssmdc/ssmdc.dart';

const notificationChannelId = 'p3pch4t_service';
const notificationId = 777;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  notificationChannelId,
  'P3pch4t Notification Service',
  description: 'This notification is used to pool for updates',
  importance: Importance.low,
);
Future<void> initializeService() async {
  // yes, we do start two instances...
  // and while this may not be the best way to do it, we need
  // to somehow communicate between two isolates
  // I have an idea to simply create a p3p mini library that
  // will just listen for events and store them in plaintext
  // for the main library to process it - but it is what it is
  // at some point this issue will be revisited but for now it
  // just works (i hope) and doesn't cause any issues.
  // If you happen to have some issues with this part of code
  // then simply open an issue and I'll hopefully revisit this
  // issue sooner.

  if (!Platform.isAndroid && !Platform.isIOS) {
    await startP3p(scheduleTasks: true, listen: true);
    p3p?.print(
      'NOTE: FlutterBackgroundService is not supported on oses other than '
      'Android and iOS',
    );
    return;
  } else {
    await startP3p(scheduleTasks: false, listen: false);
  }

  final service = FlutterBackgroundService();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in
      // separated isolate
      onStart: onStart,
      isForegroundMode: true,
      // this must match with notification channel that was created above.
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'P3pch4t',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: (service) {},
      onBackground: (service) {
        return true;
      },
    ),
  );
}

Future<void> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  // DartPluginRegistrant.ensureInitialized();
  if (p3p == null) {
    if (kDebugMode) {
      print("NOTE: it looks like p3pch4t is not loaded, let's start it");
    }
    await updateNotification(service, 'Starting', 'p3pch4t is starting');
    await startP3p(scheduleTasks: true, listen: true);
    p3p?.print('p3p started...');
  }
  if (p3p == null) {
    if (kDebugMode) {
      print('NOTE: p3p failed to start. for reason unknown to us. Sorry.');
    }
    await updateNotification(
      service,
      'Failed to start',
      "p3p was unable to initialize. That's all we know",
    );
    return;
  }
  await updateNotification(
    service,
    'P3pch4t',
    'P3pch4t is running in the background',
  );

  p3p?.print('onStart(): loop endered');
  int? lastId = -1;
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 15));

    final msg = await p3p?.db.getLastMessage();
    if (msg?.id == lastId) continue;
    lastId = msg?.id;
    if (msg == null) continue;
    final user = await msg.getSender(p3p!);
    if (kDebugMode) {
      await updateNotification(
        service,
        'DEBUG',
        '${msg.id}: ${user.name} - ${msg.text}',
      );
    }
    final msgGroup = AndroidNotificationChannelGroup(
      'msgs-${user.publicKey.fingerprint}',
      '${user.name} messages',
    );
    final msgChannel = AndroidNotificationChannel(
      'msgs-${user.publicKey.fingerprint}',
      '${user.name} messages',
      // groupId: "msgs-${user.publicKey.fingerprint}",
      description:
          'This notification is used to display messages from ${user.name}',
      importance: Importance.low,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(msgChannel);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(msgGroup);
    final notifId = 1000 + msg.id;
    await FlutterLocalNotificationsPlugin().show(
      notifId,
      user.name,
      msg.text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'msgs-${user.publicKey.fingerprint}',
          '${user.name} messages',
          icon: 'ic_bg_service_small',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

Future<void> updateNotification(
  ServiceInstance service,
  String title,
  String description,
) async {
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        description,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
    }
  }
}

final ssmdcInstances = <P3pSSMDC>[];
I2p? i2p;

@pragma('vm:entrypoint')
Future<void> startP3p({
  required bool scheduleTasks,
  required bool listen,
}) async {
  if (kDebugMode) {
    print('startP3p: starting P3pch4t {\n'
        '    scheduleTasks: $scheduleTasks,\n'
        '    listen: $listen\n'
        '}');
  }

  var appDocumentsDir = Directory(
    Platform.environment['HOME'] ?? '.p3p-data',
  );
  try {
    appDocumentsDir = await getApplicationDocumentsDirectory();
  } catch (e) {
    // We can simply ignore this error
  }

  final prefs = await SharedPreferences.getInstance();
  final filestore = p.join(appDocumentsDir.path, 'p3pch4t');
  if (kDebugMode) print('starting i2pd');
  i2p = I2p(
    storePathString: p.join(filestore, 'i2pd-data'),
    tunnels: [
      I2pdHttpTunnel(
        name: 'p3pch4tmain',
        host: '127.0.0.1',
        port: 3893,
        inport: 3893,
        keys: 'p3pch4tmain.dat',
      ),
    ],
    i2pdConf: I2pdConf(
      pidfile: p.join(filestore, 'i2pd-data', 'i2pddata', 'i2pd.pid'),
      loglevel: 'warn',
      logfile: p.join(filestore, 'i2pd-data', 'log.txt'),
      log: 'file',
      port: I2pdConf.getPort(),
      ntcp2: I2pdNtcp2Conf(),
      ssu2: I2pdSsu2Conf(),
      http: I2pdHttpConf(auth: false),
      httpproxy: I2pdHttpproxyConf(),
      socksproxy: I2pdSocksproxyConf(),
      sam: I2pdSamConf(),
      bob: I2pdBobConf(),
      i2cp: I2pdI2cpConf(),
      i2pcontrol: I2pdI2pcontrolConf(),
      precomputation: I2pdPrecomputationConf(),
      upnp: I2pdUpnpConf(),
      meshnets: I2pdMeshnetsConf(),
      reseed: I2pdReseedConf(),
      addressbook: I2pdAddressbookConf(),
      limits: I2pdLimitsConf(),
      trust: I2pdTrustConf(),
      exploratory: I2pdExploratoryConf(),
      persist: I2pdPersistConf(),
      cpuext: I2pdCpuextConf(),
    ),
    binPath: (await getAndroidNativeLibraryDirectory()).path,
    libSoHack: Platform.isAndroid,
  );
  if (listen) {
    unawaited(
      (() async {
        if (kDebugMode) print('STARTING I2P');
        final ec = await i2p?.run();
        if (kDebugMode) print('I2P exited naturally: $ec');
      })(),
    );
  }

  final eepsite = await i2p?.domainInfo('p3pch4tmain.dat');
  if (kDebugMode) print('P3p.createSession - (eepsite: $eepsite)');
  p3p = await P3p.createSession(
    filestore,
    prefs.getString('priv_key')!,
    prefs.getString('priv_passpharse') ?? 'no_passpharse',
    db.DatabaseImplDrift(
      dbFolder: p.join(filestore, 'dbdrift'),
      singularFileStore: false,
    ),
    scheduleTasks: scheduleTasks,
    listen: listen,
    reachableI2p: eepsite == null
        ? null
        : ReachableI2p(
            eepsiteAddress: eepsite,
          ),
  );

  final groups = prefs.getStringList('groups') ?? [];
  for (final group in groups) {
    ssmdcInstances.add(
      await P3pSSMDC.createGroup(
        '${p3p?.fileStorePath}/ssmdc-$group',
        scheduleTasks: scheduleTasks,
        listen: true,
      ),
    );
  }
}
