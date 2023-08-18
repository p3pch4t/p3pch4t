import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:p3p/p3p.dart';
import 'package:p3p/src/database/drift.dart' as db;
import 'package:p3pch4t/main.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  await startP3p(); // yes, we do start two instances...
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

  final service = FlutterBackgroundService();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,
      isForegroundMode: true,

      notificationChannelId:
          notificationChannelId, // this must match with notification channel you created above.
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
  DartPluginRegistrant.ensureInitialized();
  if (p3p == null) {
    print("NOTE: it looks like p3pch4t is not loaded, let's start it");
    await updateNotification(service, 'Starting', 'p3pch4t is starting');
    await startP3p();
    print('p3p started...');
  }
  if (p3p == null) {
    print('NOTE: p3p failed to start. for reason unknown to us. Sorry.');
    await updateNotification(
      service,
      'Failed to start',
      "p3p was unable to initialize. That's all we know",
    );
    await Future.delayed(const Duration(seconds: 30));
  }
  await updateNotification(
    service,
    'P3pch4t',
    'P3pch4t is running in the background',
  );

  print('called onStart:');
  int? lastId = -1;
  while (true) {
    await Future.delayed(const Duration(seconds: 15));

    final msg = await p3p!.db.getLastMessage();
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

Future<void> startP3p() async {
  print('startP3p: starting P3pch4t');
  final appDocumentsDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  p3p = await P3p.createSession(
    p.join(appDocumentsDir.path, 'p3pch4t'),
    prefs.getString('priv_key')!,
    prefs.getString('priv_passpharse') ?? 'no_passpharse',
    db.DatabaseImplDrift(
      dbFolder: p.join(appDocumentsDir.path, 'p3pch4t-dbdrift'),
    ),
  );
}
