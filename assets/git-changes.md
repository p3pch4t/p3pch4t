If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.


$ p3p.dart 

--------

On branch master
Your branch is up to date with 'origin/master'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   lib/p3p.dart
	modified:   lib/src/background.dart
	modified:   lib/src/database/abstract.dart
	modified:   lib/src/database/drift.dart
	modified:   lib/src/error.dart
	modified:   lib/src/event.dart
	modified:   lib/src/filestore.dart
	modified:   lib/src/p3p_base.dart
	modified:   lib/src/publickey.dart
	modified:   lib/src/reachable/relay.dart
	modified:   lib/src/userinfo.dart
	modified:   pubspec.yaml

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	lib/src/database/isar.dart

--------------------------------------------------
Changes not staged for commit:
diff --git i/lib/p3p.dart w/lib/p3p.dart
index f731cab..545c0fe 100644
--- i/lib/p3p.dart
+++ w/lib/p3p.dart
@@ -3,9 +3,8 @@
 /// More dartdocs go here.
 library;
 
-export 'package:objectbox/objectbox.dart';
-
 export 'src/chat.dart';
+export 'src/database/isar.dart';
 export 'src/endpoint.dart';
 export 'src/error.dart';
 export 'src/event.dart';
diff --git i/lib/src/background.dart w/lib/src/background.dart
index 1dc96ac..bcbb405 100644
--- i/lib/src/background.dart
+++ w/lib/src/background.dart
@@ -40,10 +40,10 @@ Future<Never> _processTasksLoop(
 /// processTasks - basically do everything that needs to be done on a periodic
 /// bases.
 Future<void> processTasks(P3p p3p) async {
-  // print('processTasks');
+  print('processTasks');
   final si = await p3p.getSelfInfo();
   final users = await p3p.db.getAllUserInfo();
-  // print('processTasks: users.length: ${users.length}');
+  print('processTasks: users.length: ${users.length}');
   for (final ui in users) {
     // print('schedTask: ${ui.id} - ${si.id}');
     if (ui.publicKey.fingerprint == si.publicKey.fingerprint) continue;
@@ -85,6 +85,7 @@ Future<void> processTasksRelayEventsOrIntroduce(
   final diff = DateTime.now().difference(ui.lastIntroduce).inHours;
   // re-introduce ourself frequently while the app is in development
   // In future this should be changed to like once a day / a week.
+
   if (diff > 6) {
     await ui.addEvent(
       p3p,
@@ -113,7 +114,7 @@ Future<void> processTasksFileRequest(P3p p3p, UserInfo ui, UserInfo si) async {
         felm.shouldFetch == true &&
         felm.requestedLatestVersion == false) {
       felm.requestedLatestVersion = true;
-      await p3p.db.save(felm);
+      felm.id = await p3p.db.save(felm);
       await ui.addEvent(
         p3p,
         Event(
diff --git i/lib/src/database/abstract.dart w/lib/src/database/abstract.dart
index 2c71fb4..66249d8 100644
--- i/lib/src/database/abstract.dart
+++ w/lib/src/database/abstract.dart
@@ -3,14 +3,14 @@ import 'package:p3p/p3p.dart';
 /// Abstract class that is used to store all the objects used by p3pch4t
 abstract class Database {
   /// One filestore for all users.
-  /// This is used in ssmdc, where we take care ov Event manually, and can
+  /// This is used in ssmdc, where we take care of Event manually, and can
   /// deny write access to certain users.
   /// You most likely do not want a singularFileStore, unless you are
   /// writing some kind of bot that may benefit from this kind of feature.
   final bool singularFileStore = false;
 
   /// Save *any* object used in p3p.dart to database
-  Future<void> save<T>(T elm);
+  Future<int> save<T>(T elm);
 
   /// get information about all users, sorted by lastMessage
   Future<List<UserInfo>> getAllUserInfo();
@@ -30,8 +30,8 @@ abstract class Database {
   ///  - roomFingerprint
   ///  - deleted (should we show deleted files)
   Future<List<FileStoreElement>> getFileStoreElementList({
-    required String? roomFingerprint,
-    required bool? deleted,
+    required String roomFingerprint,
+    required bool deleted,
   });
 
   /// Get the publickey based on fingerprint
@@ -43,15 +43,15 @@ abstract class Database {
   Future<UserInfo?> getUserInfo({PublicKey? publicKey, String? fingerprint});
 
   /// get all List<Event> for given PublicKey
-  Future<List<Event>> getEvents({required PublicKey? destinationPublicKey});
+  Future<List<Event>> getEvents({required PublicKey destinationPublicKey});
 
   /// get List<Message> based on a roomFingerprint
-  Future<List<Message>> getMessageList({required String? roomFingerprint});
+  Future<List<Message>> getMessageList({required String roomFingerprint});
 
   /// get Message based on either
   Future<Message?> getMessage({
-    required String? uuid,
-    required String? roomFingerprint,
+    required String uuid,
+    required String roomFingerprint,
   });
 
   /// get Message that was sent last
diff --git i/lib/src/database/drift.dart w/lib/src/database/drift.dart
index baa6ac4..5b886a9 100644
--- i/lib/src/database/drift.dart
+++ w/lib/src/database/drift.dart
@@ -99,6 +99,7 @@ class FileStoreElements extends Table {
     FileStoreElements,
   ],
 )
+@Deprecated('Replaced with Isar.')
 class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
   DatabaseImplDrift({required String dbFolder, required this.singularFileStore})
       : super(_openConnection(dbFolder)) {
@@ -111,12 +112,12 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
   int get schemaVersion => 1;
 
   @override
-  Future<void> save<T>(T elm) async {
+  Future<int> save<T>(T elm) async {
     // print('[driftdb] save($T elm):');
-    await _save(elm);
+    return await _save(elm);
   }
 
-  Future<void> _save<T>(T elm) async {
+  Future<int> _save<T>(T elm) async {
     switch (T) {
       case ppp.Message:
         if (elm is ppp.Message) {
@@ -132,15 +133,14 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
             dateReceived: elm.dateReceived,
           );
           if (elm.id == -1) {
-            await into(messages).insert(iq);
+            return await into(messages).insert(iq);
           } else {
-            await into(messages).insertOnConflictUpdate(iq);
+            return await into(messages).insertOnConflictUpdate(iq);
           }
         }
-        return;
       case ppp.Endpoint:
         if (elm is ppp.Endpoint) {
-          await into(endpoints).insertOnConflictUpdate(
+          return await into(endpoints).insertOnConflictUpdate(
             EndpointsCompanion.insert(
               id: elm.id == -1 ? const Value.absent() : Value(elm.id),
               protocol: elm.protocol,
@@ -151,10 +151,9 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
             ),
           );
         }
-        return;
       case ppp.P3pError:
         if (elm is ppp.P3pError) {
-          await into(errors).insertOnConflictUpdate(
+          return await into(errors).insertOnConflictUpdate(
             ErrorsCompanion.insert(
               id: elm.id == -1 ? const Value.absent() : Value(elm.id),
               code: elm.code,
@@ -163,13 +162,12 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
             ),
           );
         }
-        return;
       case ppp.Event:
         if (elm is ppp.Event) {
           if (elm.destinationPublicKey != null) {
-            await save(elm.destinationPublicKey!);
+            return await save(elm.destinationPublicKey!);
           }
-          await into(events).insertOnConflictUpdate(
+          return await into(events).insertOnConflictUpdate(
             EventsCompanion.insert(
               id: elm.id == -1 ? const Value.absent() : Value(elm.id),
               eventTypeIndex:
@@ -183,7 +181,6 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
             ),
           );
         }
-        return;
       case ppp.PublicKey:
         if (elm is ppp.PublicKey) {
           final pq = PublicKeysCompanion.insert(
@@ -194,16 +191,14 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
             ..where((tbl) => tbl.fingerprint.equals(elm.fingerprint));
           final qresult = await q.getSingleOrNull();
           if (qresult == null) {
-            await into(publicKeys).insertOnConflictUpdate(pq);
+            return await into(publicKeys).insertOnConflictUpdate(pq);
           }
-          return;
         }
-        return;
       case ppp.UserInfo:
         if (elm is ppp.UserInfo) {
           if (await getPublicKey(fingerprint: elm.publicKey.fingerprint) ==
               null) {
-            await save(elm.publicKey);
+            elm.publicKey.id = await save(elm.publicKey);
           }
           if (elm.endpoint.isNotEmpty) {
             final q = delete(userInfoEndpoints)
@@ -237,13 +232,13 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
             name: Value(elm.name),
           );
           if (ui == null) {
-            await into(userInfos).insert(pi);
+            return await into(userInfos).insert(pi);
           } else {
             final q = update(userInfos);
             await q.replace(pi);
+            return pi.id.value;
           }
         }
-        return;
       case ppp.FileStoreElement:
         if (elm is ppp.FileStoreElement) {
           final q = select(fileStoreElements)
@@ -271,12 +266,12 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
           );
 
           if (selm == null) {
-            await into(fileStoreElements).insert(pi);
+            return await into(fileStoreElements).insert(pi);
           } else {
             await update(fileStoreElements).replace(pi);
+            return -1;
           }
         }
-        return;
     }
     throw Exception('$T is not supported by save();');
   }
@@ -298,7 +293,7 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
       ret.add(
         ppp.UserInfo(
           id: element.id,
-          publicKey: (await getPublicKey(fingerprint: element.publicKey))!,
+          publicKey: (await getPublicKey(fingerprint: element.publicKey)),
           endpoint: await getUserInfoEndpointList(userInfoId: element.id),
         )
           ..name = element.name
@@ -335,7 +330,7 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
           destinationPublicKey: await getPublicKey(
             fingerprint: elm.destinationPublicKeyFingerprint,
           ),
-          data: await EventData.fromJson(
+          data: EventData.fromJson(
             json.decode(utf8.decode(elm.dataJson)) as Map<String, dynamic>,
             EventType.values[elm.eventTypeIndex],
           ),
@@ -501,7 +496,7 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
 
     return ppp.UserInfo(
       id: ui.id,
-      publicKey: publicKey!,
+      publicKey: publicKey,
       endpoint: await getUserInfoEndpointList(userInfoId: ui.id),
     )
       ..name = ui.name
diff --git i/lib/src/error.dart w/lib/src/error.dart
index 4150ee0..24404e1 100644
--- i/lib/src/error.dart
+++ w/lib/src/error.dart
@@ -7,7 +7,7 @@ class P3pError {
   });
 
   /// id, -1 to insert new
-  final int id = -1;
+  int id = -1;
 
   /// what is the error code?
   final int code;
@@ -16,7 +16,7 @@ class P3pError {
   final String info;
 
   /// when did it occur
-  final DateTime errorDate = DateTime.now();
+  DateTime errorDate = DateTime.now();
 
   @override
   String toString() {
diff --git i/lib/src/event.dart w/lib/src/event.dart
index 095b5ac..3ffcf89 100644
--- i/lib/src/event.dart
+++ w/lib/src/event.dart
@@ -4,6 +4,7 @@ import 'dart:convert';
 import 'dart:typed_data';
 
 import 'package:dart_pg/dart_pg.dart' as pgp;
+import 'package:isar/isar.dart';
 import 'package:p3p/p3p.dart';
 import 'package:uuid/uuid.dart';
 
@@ -38,8 +39,10 @@ class Event {
   EventType eventType;
   String? encryptPrivkeyArmored;
   String? encryptPrivkeyPassowrd;
+  @ignore // make isar generator happy
   PublicKey? destinationPublicKey;
   // Map<String, dynamic> data;
+  @ignore // make isar generator happy
   EventData? data;
   String uuid = const Uuid().v4();
 
@@ -54,7 +57,7 @@ class Event {
   static Future<Event> fromJson(Map<String, dynamic> json) async {
     return Event(
       eventType: toEventType(json['type'] as String),
-      data: await EventData.fromJson(
+      data: EventData.fromJson(
         json['data'] as Map<String, dynamic>,
         toEventType(json['type'] as String),
       ),
@@ -165,13 +168,13 @@ class Event {
       final evt = await Event.fromJson(elm as Map<String, dynamic>);
       if (userInfo == null && evt.eventType == EventType.introduce) {
         userInfo = UserInfo(
-          publicKey: (await PublicKey.create(
+          publicKey: await PublicKey.create(
             p3p,
             (evt.data! as EventIntroduce).publickey.armor(),
-          ))!,
+          ),
           endpoint: [...ReachableRelay.getDefaultEndpoints(p3p)],
         );
-        await p3p.db.save(userInfo);
+        userInfo.id = await p3p.db.save(userInfo);
       }
       ret.events.add(await Event.fromJson(elm));
     }
@@ -243,7 +246,7 @@ class Event {
           await p3p.db.getPublicKey(fingerprint: edata.publickey.fingerprint),
     );
     useri ??= UserInfo(
-      publicKey: (await PublicKey.create(p3p, edata.publickey.armor()))!,
+      publicKey: await PublicKey.create(p3p, edata.publickey.armor()),
       endpoint: [
         ...ReachableRelay.getDefaultEndpoints(p3p),
       ],
@@ -253,7 +256,7 @@ class Event {
     }
     useri.name = edata.username;
 
-    await p3p.db.save(useri);
+    useri.id = await p3p.db.save(useri);
     return true;
   }
 
@@ -267,7 +270,7 @@ class Event {
     );
     final selfUser = await p3p.getSelfInfo();
     userInfo ??= UserInfo(
-      publicKey: (await PublicKey.create(p3p, edata.publickey as String))!,
+      publicKey: await PublicKey.create(p3p, edata.publickey as String),
       endpoint: edata.endpoint..addAll(ReachableRelay.getDefaultEndpoints(p3p)),
     );
 
@@ -368,7 +371,7 @@ class Event {
     }
     await file.file.writeAsBytes(incomingFile.bytes);
     file.sha512sum = FileStoreElement.calcSha512Sum(incomingFile.bytes);
-    await p3p.db.save(file);
+    file.id = await p3p.db.save(file);
     return true;
   }
 
@@ -396,7 +399,7 @@ class Event {
             ..isDeleted = elm.isDeleted
             ..modifyTime = elm.modifyTime
             ..requestedLatestVersion = false;
-          await p3p.db.save(elmStored);
+          elmStored.id = await p3p.db.save(elmStored);
         } else {
           p3p.print('ignoring because\n'
               ' - remote:${elm.modifyTime}'
@@ -440,13 +443,13 @@ class ParsedPayload {
 }
 
 abstract class EventData {
-  static Future<EventData?> fromJson(
+  static EventData? fromJson(
     Map<String, dynamic> data,
     EventType type,
-  ) async {
+  ) {
     return switch (type) {
-      EventType.introduce => await EventIntroduce.fromJson(data),
-      EventType.introduceRequest => await EventIntroduceRequest.fromJson(data),
+      EventType.introduce => EventIntroduce.fromJson(data),
+      EventType.introduceRequest => EventIntroduceRequest.fromJson(data),
       EventType.message => EventMessage.fromJson(data),
       EventType.fileRequest => EventFileRequest.fromJson(data),
       EventType.file => EventFile.fromJson(data),
@@ -482,14 +485,14 @@ class EventIntroduce implements EventData {
     };
   }
 
-  static Future<EventIntroduce> fromJson(Map<String, dynamic> data) async {
+  static EventIntroduce fromJson(Map<String, dynamic> data) {
     final endps = <String>[];
     for (final elm in data['endpoint'] as List<dynamic>) {
       endps.add(elm.toString());
     }
 
     return EventIntroduce(
-      publickey: await pgp.OpenPGP.readPublicKey(data['publickey'] as String),
+      publickey: pgp.PublicKey.fromArmored(data['publickey'] as String),
       endpoint: Endpoint.fromStringList(endps),
       username: data['username'] as String,
     );
@@ -537,16 +540,16 @@ class EventIntroduceRequest implements EventData {
     };
   }
 
-  static Future<EventIntroduceRequest> fromJson(
+  static EventIntroduceRequest fromJson(
     Map<String, dynamic> data,
-  ) async {
+  ) {
     final endps = <String>[];
     for (final elm in data['endpoint'] as List<dynamic>) {
       endps.add(elm.toString());
     }
 
     return EventIntroduceRequest(
-      publickey: await pgp.OpenPGP.readPublicKey(data['publickey'] as String),
+      publickey: pgp.PublicKey.fromArmored(data['publickey'] as String),
       endpoint: Endpoint.fromStringList(endps),
     );
   }
diff --git i/lib/src/filestore.dart w/lib/src/filestore.dart
index 7571d47..81f49b0 100644
--- i/lib/src/filestore.dart
+++ w/lib/src/filestore.dart
@@ -1,6 +1,7 @@
 import 'dart:io';
 import 'dart:typed_data';
 import 'package:crypto/crypto.dart' as crypto;
+import 'package:isar/isar.dart';
 import 'package:p3p/p3p.dart';
 import 'package:path/path.dart' as p;
 import 'package:uuid/uuid.dart';
@@ -67,6 +68,7 @@ class FileStoreElement {
   bool shouldFetch = false;
 
   /// File() object pointing to the file.
+  @ignore // make isar happy
   File get file => File(localPath);
 
   /// What is the roomFingerprint that this file belongs to?
@@ -93,7 +95,7 @@ class FileStoreElement {
           ),
         );
 
-        await p3p.db.save(this);
+        id = await p3p.db.save(this);
         p3p.callOnFileStoreElement(
           FileStore(roomFingerprint: roomFingerprint),
           this,
@@ -110,7 +112,7 @@ class FileStoreElement {
         ),
       );
 
-      await p3p.db.save(this);
+      id = await p3p.db.save(this);
       p3p.callOnFileStoreElement(
         FileStore(roomFingerprint: roomFingerprint),
         this,
@@ -150,7 +152,7 @@ class FileStoreElement {
         ),
       );
     }
-    await p3p.db.save(this);
+    id = await p3p.db.save(this);
   }
 
   /// calculate sha512sum of Uing8List
@@ -191,7 +193,7 @@ class FileStore {
     );
   }
 
-  /// Put a FileStoreElement and return it's newer version
+  /// Put a FileStoreElement and return it's newer version or create a new file
   Future<FileStoreElement> putFileStoreElement(
     P3p p3p, {
     required File? localFile,
@@ -200,6 +202,7 @@ class FileStore {
     required String fileInChatPath,
     required String? uuid,
   }) async {
+    // fill the uuid if doesn't exist.
     uuid ??= const Uuid().v4();
     final sha512sum = localFileSha512sum ??
         FileStoreElement.calcSha512Sum(
@@ -223,6 +226,8 @@ class FileStore {
       roomFingerprint: roomFingerprint,
       uuid: uuid,
     );
+    print('${fselm?.roomFingerprint} $roomFingerprint');
+    print('${fselm?.uuid} $uuid');
     fselm ??= FileStoreElement(
       path: '/',
       /* replaced lated by ..path = ... */
@@ -239,7 +244,7 @@ class FileStore {
               fileInChatPath.startsWith('.config'))
       ..path = fileInChatPath
       ..uuid = uuid;
-    await p3p.db.save(fselm);
+    fselm.id = await p3p.db.save(fselm);
     final useri = await p3p.db.getUserInfo(
       publicKey: await p3p.db.getPublicKey(fingerprint: roomFingerprint),
     );
@@ -252,7 +257,7 @@ class FileStore {
         data: EventFileMetadata(files: [fselm]),
       ),
     );
-    await p3p.db.save(useri);
+    useri.id = await p3p.db.save(useri);
     return fselm;
   }
 }
diff --git i/lib/src/p3p_base.dart w/lib/src/p3p_base.dart
index 0d99c96..acc1110 100644
--- i/lib/src/p3p_base.dart
+++ w/lib/src/p3p_base.dart
@@ -94,20 +94,23 @@ class P3p {
 
   /// Get UserInfo object about owner of this object
   Future<UserInfo> getSelfInfo() async {
-    final pubKey = await db.getPublicKey(fingerprint: privateKey.fingerprint);
-
-    var useri = await db.getUserInfo(
+    var pubKey = await db.getPublicKey(fingerprint: privateKey.fingerprint);
+    if (pubKey != null) {
+      final useri = await db.getUserInfo(
+        publicKey: pubKey,
+      );
+      if (useri != null) return useri;
+    } else {
+      pubKey = await PublicKey.create(this, privateKey.toPublic.armor());
+      pubKey!.id = await db.save(pubKey);
+    }
+    final useri = UserInfo(
       publicKey: pubKey,
-    );
-    if (useri != null) return useri;
-    useri = UserInfo(
-      publicKey: (await PublicKey.create(this, privateKey.toPublic.armor()))!,
       endpoint: [
-        // ...ReachableLocal.defaultEndpoints,
         ...ReachableRelay.getDefaultEndpoints(this),
       ],
     )..name = 'localuser [${privateKey.keyID}]';
-    await db.save(useri);
+    useri.id = await db.save(useri);
     return useri;
   }
 
@@ -185,8 +188,8 @@ class P3p {
   }
 
   /// List<Function> of all callbacks that will be called on new messages.
-  List<void Function(P3p p3p, Message msg, UserInfo user)> onMessageCallback =
-      [];
+  final onMessageCallback =
+      <void Function(P3p p3p, Message msg, UserInfo user)>[];
 
   /// Used internally to call onMessageCallback
   Future<void> callOnMessage(Message msg) async {
@@ -208,8 +211,8 @@ class P3p {
   /// However if new event arrives it will execute normally.
   /// Avoid long blocking of events to not render your peer
   /// unresponsive or to not have out of sync events in database.
-  List<Future<bool> Function(P3p p3p, Event evt, UserInfo ui)> onEventCallback =
-      [];
+  final onEventCallback =
+      <Future<bool> Function(P3p p3p, Event evt, UserInfo ui)>[];
 
   /// see: onEventCallback
   /// Used internally to call onEventCallback
@@ -229,8 +232,8 @@ class P3p {
   ///  - at some other points too
   /// If you want to block file edit or intercept it you should be
   /// using onEventCallback (in most cases)
-  List<void Function(P3p p3p, FileStore fs, FileStoreElement fselm)>
-      onFileStoreElementCallback = [];
+  final onFileStoreElementCallback =
+      <void Function(P3p p3p, FileStore fs, FileStoreElement fselm)>[];
 
   /// see: onFileStoreElementCallback
   void callOnFileStoreElement(FileStore fs, FileStoreElement fselm) {
diff --git i/lib/src/publickey.dart w/lib/src/publickey.dart
index 39ff723..e91afb4 100644
--- i/lib/src/publickey.dart
+++ w/lib/src/publickey.dart
@@ -9,6 +9,8 @@ class PublicKey {
     required this.publickey,
   });
 
+  int id = -1;
+
   /// Create publickey from armored string
   static Future<PublicKey?> create(
     P3p p3p,
@@ -21,19 +23,19 @@ class PublicKey {
         fingerprint: publicKey.fingerprint,
         publickey: publicKey.armor(),
       );
-      await p3p.db.save(pubkeyret);
+      pubkeyret.id = await p3p.db.save(pubkeyret);
       return pubkeyret;
     } catch (e) {
-      p3p.print(e);
+      print(e);
     }
     return null;
   }
 
   /// Key's fingerprint
-  String fingerprint;
+  final String fingerprint;
 
   /// armored publickey
-  String publickey;
+  final String publickey;
 
   /// encrypt for this publickey and sign by privatekey
   Future<String> encrypt(String data, pgp.PrivateKey privatekey) async {
diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
index 1a1d3c7..2f1952c 100644
--- i/lib/src/reachable/relay.dart
+++ w/lib/src/reachable/relay.dart
@@ -46,7 +46,7 @@ class ReachableRelay implements Reachable {
   }
 
   @override
-  List<String> protocols = ['relay', 'relays'];
+  List<String> protocols = ['relay', 'relays', 'i2p'];
 
   @override
   Future<P3pError?> reach({
@@ -150,6 +150,8 @@ class ReachableRelay implements Reachable {
           await generateAuth(endp, p3p.privateKey),
         ),
       ),
+      if (endp.protocol == 'i2p')
+        'relay-host': endp.toString().replaceAll('i2p://', 'http://'),
     };
   }
 
diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
index 904f4b4..5ec2c56 100644
--- i/lib/src/userinfo.dart
+++ w/lib/src/userinfo.dart
@@ -1,24 +1,31 @@
 import 'dart:convert';
 
+import 'package:isar/isar.dart';
 import 'package:p3p/p3p.dart';
 
 /// Information about user, together with helper functions
 class UserInfo {
   /// You shouldn't use this function, use UserInfo.create instead.
   UserInfo({
-    required this.publicKey,
+    required PublicKey? publicKey,
     required this.endpoint,
     this.id = -1,
     this.name,
-  });
+  }) {
+    if (publicKey != null) {
+      this.publicKey = publicKey;
+    }
+  }
 
   /// id, -1 means insert to database as new.
   int id = -1;
 
   /// PublicKey to identify the user
-  PublicKey publicKey;
+  @ignore // make isar happy
+  late PublicKey publicKey;
 
   /// Places where we can reach given user
+  @ignore // make isar happy
   List<Endpoint> endpoint;
 
   /// User's display name, if null we will send introduce.request
@@ -34,6 +41,7 @@ class UserInfo {
   DateTime lastEvent = DateTime.fromMicrosecondsSinceEpoch(0);
 
   /// getter for the given UserInfo's filestore
+  @ignore // make isar happy
   FileStore get fileStore => FileStore(roomFingerprint: publicKey.fingerprint);
 
   /// Get all messages and sort them based on when they got received
@@ -54,8 +62,8 @@ class UserInfo {
       message.id = msg.id;
     }
     lastMessage = DateTime.now();
-    await p3p.db.save(this);
-    await p3p.db.save(message);
+    id = await p3p.db.save(this);
+    message.id = await p3p.db.save(message);
     await p3p.callOnMessage(message);
   }
 
@@ -68,7 +76,7 @@ class UserInfo {
       // p3p.print('fixing endpoint by adding ReachableRelay.defaultEndpoints');
       endpoint = ReachableRelay.getDefaultEndpoints(p3p);
     }
-
+    print('111');
     // 1. Get all events
     final evts = await p3p.db.getEvents(destinationPublicKey: publicKey);
 
@@ -107,7 +115,14 @@ class UserInfo {
             );
           case 'i2p':
             if (p3p.reachableI2p != null) {
-              resp = await p3p.reachableI2p!.reach(
+              resp = await p3p.reachableI2p?.reach(
+                p3p: p3p,
+                endpoint: endp,
+                message: body,
+                publicKey: publicKey,
+              );
+            } else {
+              resp = await p3p.reachableRelay.reach(
                 p3p: p3p,
                 endpoint: endp,
                 message: body,
@@ -155,16 +170,19 @@ class UserInfo {
     }
     lastEvent = DateTime.now();
     evt.destinationPublicKey = publicKey;
-    await p3p.db.save(evt);
-    await p3p.db.save(this);
+    evt.id = await p3p.db.save(evt);
+    id = await p3p.db.save(this);
   }
 
   /// create new UserInfo object, with sane defaults and store it in Database
+  /// `any` can be anything that may resolve to user, for now this includes:
+  /// - Fingerprint
+  //TODO(mrcyjanek): Add some kind of fingerprint database?
   static Future<UserInfo?> create(
     P3p p3p,
-    String publicKey,
+    String any,
   ) async {
-    final pubKey = await PublicKey.create(p3p, publicKey);
+    final pubKey = await PublicKey.create(p3p, any);
     if (pubKey == null) return null;
     final ui = UserInfo(
       publicKey: pubKey,
@@ -172,7 +190,7 @@ class UserInfo {
         ...ReachableRelay.getDefaultEndpoints(p3p),
       ],
     );
-    await p3p.db.save(ui);
+    ui.id = await p3p.db.save(ui);
     return ui;
   }
 }
diff --git i/pubspec.yaml w/pubspec.yaml
index d57c095..f99371d 100644
--- i/pubspec.yaml
+++ w/pubspec.yaml
@@ -12,9 +12,9 @@ dependencies:
   dart_pg: ^1.1.5
   dio: ^5.3.2
   drift: ^2.11.0
+  isar: ^3.1.0+1
   logger: ^2.0.2
   mutex: ^3.0.1
-  objectbox: ^2.2.0
   path: ^1.8.3
   rxdart: ^0.27.7
   shelf: ^1.4.1
@@ -25,6 +25,7 @@ dependencies:
 dev_dependencies:
   build_runner: ^2.4.6
   drift_dev: ^2.11.0
+  isar_generator: ^3.1.0+1
   lints: ^2.0.0
   test: ^1.21.0
-  very_good_analysis: ^5.0.0+1
\ No newline at end of file
+  very_good_analysis: ^5.0.0+1
no changes added to commit (use "git add" and/or "git commit -a")


$ p3pch4t 

--------

On branch master
Your branch is up to date with 'origin/master'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   android/app/src/main/AndroidManifest.xml
	modified:   assets/git-changes.md
	modified:   lib/main.dart
	modified:   lib/pages/adduser.dart
	modified:   lib/pages/fileview.dart
	modified:   lib/pages/landing.dart
	modified:   lib/pages/settings.dart
	modified:   lib/pages/webxdcfileview_android.dart
	modified:   lib/platform_interface.dart
	modified:   lib/service.dart
	modified:   linux/flutter/generated_plugin_registrant.cc
	modified:   linux/flutter/generated_plugins.cmake
	modified:   macos/Flutter/GeneratedPluginRegistrant.swift
	modified:   pubspec.lock
	modified:   pubspec.yaml
	modified:   windows/flutter/generated_plugin_registrant.cc
	modified:   windows/flutter/generated_plugins.cmake

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	lib/pages/register.dart

--------------------------------------------------
Changes not staged for commit:
diff --git i/android/app/src/main/AndroidManifest.xml w/android/app/src/main/AndroidManifest.xml
index 00ff038..bd5f1a4 100644
--- i/android/app/src/main/AndroidManifest.xml
+++ w/android/app/src/main/AndroidManifest.xml
@@ -38,4 +38,7 @@
     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
     <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
+    <uses-permission android:name="android.permission.CAMERA" />
+    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
+    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
 </manifest>
diff --git i/assets/git-changes.md w/assets/git-changes.md
index 3a5e193..a645c8b 100644
--- i/assets/git-changes.md
+++ w/assets/git-changes.md
@@ -1 +1,3323 @@
 If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.
+
+
+$ p3p.dart 
+
+--------
+
+On branch master
+Your branch is up to date with 'origin/master'.
+
+Changes not staged for commit:
+  (use "git add <file>..." to update what will be committed)
+  (use "git restore <file>..." to discard changes in working directory)
+	modified:   lib/p3p.dart
+	modified:   lib/src/background.dart
+	modified:   lib/src/database/abstract.dart
+	modified:   lib/src/database/drift.dart
+	modified:   lib/src/error.dart
+	modified:   lib/src/event.dart
+	modified:   lib/src/filestore.dart
+	modified:   lib/src/p3p_base.dart
+	modified:   lib/src/publickey.dart
+	modified:   lib/src/reachable/relay.dart
+	modified:   lib/src/userinfo.dart
+	modified:   pubspec.yaml
+
+Untracked files:
+  (use "git add <file>..." to include in what will be committed)
+	lib/src/database/isar.dart
+
+--------------------------------------------------
+Changes not staged for commit:
+diff --git i/lib/p3p.dart w/lib/p3p.dart
+index f731cab..545c0fe 100644
+--- i/lib/p3p.dart
++++ w/lib/p3p.dart
+@@ -3,9 +3,8 @@
+ /// More dartdocs go here.
+ library;
+ 
+-export 'package:objectbox/objectbox.dart';
+-
+ export 'src/chat.dart';
++export 'src/database/isar.dart';
+ export 'src/endpoint.dart';
+ export 'src/error.dart';
+ export 'src/event.dart';
+diff --git i/lib/src/background.dart w/lib/src/background.dart
+index 1dc96ac..f1331e5 100644
+--- i/lib/src/background.dart
++++ w/lib/src/background.dart
+@@ -40,10 +40,10 @@ Future<Never> _processTasksLoop(
+ /// processTasks - basically do everything that needs to be done on a periodic
+ /// bases.
+ Future<void> processTasks(P3p p3p) async {
+-  // print('processTasks');
++  print('processTasks');
+   final si = await p3p.getSelfInfo();
+   final users = await p3p.db.getAllUserInfo();
+-  // print('processTasks: users.length: ${users.length}');
++  print('processTasks: users.length: ${users.length}');
+   for (final ui in users) {
+     // print('schedTask: ${ui.id} - ${si.id}');
+     if (ui.publicKey.fingerprint == si.publicKey.fingerprint) continue;
+@@ -85,6 +85,7 @@ Future<void> processTasksRelayEventsOrIntroduce(
+   final diff = DateTime.now().difference(ui.lastIntroduce).inHours;
+   // re-introduce ourself frequently while the app is in development
+   // In future this should be changed to like once a day / a week.
++
+   if (diff > 6) {
+     await ui.addEvent(
+       p3p,
+diff --git i/lib/src/database/abstract.dart w/lib/src/database/abstract.dart
+index 2c71fb4..7ea59c5 100644
+--- i/lib/src/database/abstract.dart
++++ w/lib/src/database/abstract.dart
+@@ -30,8 +30,8 @@ abstract class Database {
+   ///  - roomFingerprint
+   ///  - deleted (should we show deleted files)
+   Future<List<FileStoreElement>> getFileStoreElementList({
+-    required String? roomFingerprint,
+-    required bool? deleted,
++    required String roomFingerprint,
++    required bool deleted,
+   });
+ 
+   /// Get the publickey based on fingerprint
+@@ -43,15 +43,15 @@ abstract class Database {
+   Future<UserInfo?> getUserInfo({PublicKey? publicKey, String? fingerprint});
+ 
+   /// get all List<Event> for given PublicKey
+-  Future<List<Event>> getEvents({required PublicKey? destinationPublicKey});
++  Future<List<Event>> getEvents({required PublicKey destinationPublicKey});
+ 
+   /// get List<Message> based on a roomFingerprint
+-  Future<List<Message>> getMessageList({required String? roomFingerprint});
++  Future<List<Message>> getMessageList({required String roomFingerprint});
+ 
+   /// get Message based on either
+   Future<Message?> getMessage({
+-    required String? uuid,
+-    required String? roomFingerprint,
++    required String uuid,
++    required String roomFingerprint,
+   });
+ 
+   /// get Message that was sent last
+diff --git i/lib/src/database/drift.dart w/lib/src/database/drift.dart
+index baa6ac4..1d1e133 100644
+--- i/lib/src/database/drift.dart
++++ w/lib/src/database/drift.dart
+@@ -99,6 +99,7 @@ class FileStoreElements extends Table {
+     FileStoreElements,
+   ],
+ )
++@Deprecated('Replaced with Isar.')
+ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
+   DatabaseImplDrift({required String dbFolder, required this.singularFileStore})
+       : super(_openConnection(dbFolder)) {
+@@ -298,7 +299,7 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
+       ret.add(
+         ppp.UserInfo(
+           id: element.id,
+-          publicKey: (await getPublicKey(fingerprint: element.publicKey))!,
++          publicKey: (await getPublicKey(fingerprint: element.publicKey)),
+           endpoint: await getUserInfoEndpointList(userInfoId: element.id),
+         )
+           ..name = element.name
+@@ -335,7 +336,7 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
+           destinationPublicKey: await getPublicKey(
+             fingerprint: elm.destinationPublicKeyFingerprint,
+           ),
+-          data: await EventData.fromJson(
++          data: EventData.fromJson(
+             json.decode(utf8.decode(elm.dataJson)) as Map<String, dynamic>,
+             EventType.values[elm.eventTypeIndex],
+           ),
+@@ -501,7 +502,7 @@ class DatabaseImplDrift extends _$DatabaseImplDrift implements Database {
+ 
+     return ppp.UserInfo(
+       id: ui.id,
+-      publicKey: publicKey!,
++      publicKey: publicKey,
+       endpoint: await getUserInfoEndpointList(userInfoId: ui.id),
+     )
+       ..name = ui.name
+diff --git i/lib/src/error.dart w/lib/src/error.dart
+index 4150ee0..24404e1 100644
+--- i/lib/src/error.dart
++++ w/lib/src/error.dart
+@@ -7,7 +7,7 @@ class P3pError {
+   });
+ 
+   /// id, -1 to insert new
+-  final int id = -1;
++  int id = -1;
+ 
+   /// what is the error code?
+   final int code;
+@@ -16,7 +16,7 @@ class P3pError {
+   final String info;
+ 
+   /// when did it occur
+-  final DateTime errorDate = DateTime.now();
++  DateTime errorDate = DateTime.now();
+ 
+   @override
+   String toString() {
+diff --git i/lib/src/event.dart w/lib/src/event.dart
+index 095b5ac..4d0874d 100644
+--- i/lib/src/event.dart
++++ w/lib/src/event.dart
+@@ -4,6 +4,7 @@ import 'dart:convert';
+ import 'dart:typed_data';
+ 
+ import 'package:dart_pg/dart_pg.dart' as pgp;
++import 'package:isar/isar.dart';
+ import 'package:p3p/p3p.dart';
+ import 'package:uuid/uuid.dart';
+ 
+@@ -38,8 +39,10 @@ class Event {
+   EventType eventType;
+   String? encryptPrivkeyArmored;
+   String? encryptPrivkeyPassowrd;
++  @ignore // make isar generator happy
+   PublicKey? destinationPublicKey;
+   // Map<String, dynamic> data;
++  @ignore // make isar generator happy
+   EventData? data;
+   String uuid = const Uuid().v4();
+ 
+@@ -54,7 +57,7 @@ class Event {
+   static Future<Event> fromJson(Map<String, dynamic> json) async {
+     return Event(
+       eventType: toEventType(json['type'] as String),
+-      data: await EventData.fromJson(
++      data: EventData.fromJson(
+         json['data'] as Map<String, dynamic>,
+         toEventType(json['type'] as String),
+       ),
+@@ -440,13 +443,13 @@ class ParsedPayload {
+ }
+ 
+ abstract class EventData {
+-  static Future<EventData?> fromJson(
++  static EventData? fromJson(
+     Map<String, dynamic> data,
+     EventType type,
+-  ) async {
++  ) {
+     return switch (type) {
+-      EventType.introduce => await EventIntroduce.fromJson(data),
+-      EventType.introduceRequest => await EventIntroduceRequest.fromJson(data),
++      EventType.introduce => EventIntroduce.fromJson(data),
++      EventType.introduceRequest => EventIntroduceRequest.fromJson(data),
+       EventType.message => EventMessage.fromJson(data),
+       EventType.fileRequest => EventFileRequest.fromJson(data),
+       EventType.file => EventFile.fromJson(data),
+@@ -482,14 +485,14 @@ class EventIntroduce implements EventData {
+     };
+   }
+ 
+-  static Future<EventIntroduce> fromJson(Map<String, dynamic> data) async {
++  static EventIntroduce fromJson(Map<String, dynamic> data) {
+     final endps = <String>[];
+     for (final elm in data['endpoint'] as List<dynamic>) {
+       endps.add(elm.toString());
+     }
+ 
+     return EventIntroduce(
+-      publickey: await pgp.OpenPGP.readPublicKey(data['publickey'] as String),
++      publickey: pgp.PublicKey.fromArmored(data['publickey'] as String),
+       endpoint: Endpoint.fromStringList(endps),
+       username: data['username'] as String,
+     );
+@@ -537,16 +540,16 @@ class EventIntroduceRequest implements EventData {
+     };
+   }
+ 
+-  static Future<EventIntroduceRequest> fromJson(
++  static EventIntroduceRequest fromJson(
+     Map<String, dynamic> data,
+-  ) async {
++  ) {
+     final endps = <String>[];
+     for (final elm in data['endpoint'] as List<dynamic>) {
+       endps.add(elm.toString());
+     }
+ 
+     return EventIntroduceRequest(
+-      publickey: await pgp.OpenPGP.readPublicKey(data['publickey'] as String),
++      publickey: pgp.PublicKey.fromArmored(data['publickey'] as String),
+       endpoint: Endpoint.fromStringList(endps),
+     );
+   }
+diff --git i/lib/src/filestore.dart w/lib/src/filestore.dart
+index 7571d47..35380ea 100644
+--- i/lib/src/filestore.dart
++++ w/lib/src/filestore.dart
+@@ -1,6 +1,7 @@
+ import 'dart:io';
+ import 'dart:typed_data';
+ import 'package:crypto/crypto.dart' as crypto;
++import 'package:isar/isar.dart';
+ import 'package:p3p/p3p.dart';
+ import 'package:path/path.dart' as p;
+ import 'package:uuid/uuid.dart';
+@@ -67,6 +68,7 @@ class FileStoreElement {
+   bool shouldFetch = false;
+ 
+   /// File() object pointing to the file.
++  @ignore // make isar happy
+   File get file => File(localPath);
+ 
+   /// What is the roomFingerprint that this file belongs to?
+@@ -191,7 +193,7 @@ class FileStore {
+     );
+   }
+ 
+-  /// Put a FileStoreElement and return it's newer version
++  /// Put a FileStoreElement and return it's newer version or create a new file
+   Future<FileStoreElement> putFileStoreElement(
+     P3p p3p, {
+     required File? localFile,
+@@ -200,6 +202,7 @@ class FileStore {
+     required String fileInChatPath,
+     required String? uuid,
+   }) async {
++    // fill the uuid if doesn't exist.
+     uuid ??= const Uuid().v4();
+     final sha512sum = localFileSha512sum ??
+         FileStoreElement.calcSha512Sum(
+@@ -223,6 +226,8 @@ class FileStore {
+       roomFingerprint: roomFingerprint,
+       uuid: uuid,
+     );
++    print('${fselm?.roomFingerprint} $roomFingerprint');
++    print('${fselm?.uuid} $uuid');
+     fselm ??= FileStoreElement(
+       path: '/',
+       /* replaced lated by ..path = ... */
+diff --git i/lib/src/p3p_base.dart w/lib/src/p3p_base.dart
+index 0d99c96..449e66f 100644
+--- i/lib/src/p3p_base.dart
++++ w/lib/src/p3p_base.dart
+@@ -95,15 +95,15 @@ class P3p {
+   /// Get UserInfo object about owner of this object
+   Future<UserInfo> getSelfInfo() async {
+     final pubKey = await db.getPublicKey(fingerprint: privateKey.fingerprint);
+-
+-    var useri = await db.getUserInfo(
+-      publicKey: pubKey,
+-    );
+-    if (useri != null) return useri;
+-    useri = UserInfo(
+-      publicKey: (await PublicKey.create(this, privateKey.toPublic.armor()))!,
++    if (pubKey != null) {
++      final useri = await db.getUserInfo(
++        publicKey: pubKey,
++      );
++      if (useri != null) return useri;
++    }
++    final useri = UserInfo(
++      publicKey: (await PublicKey.create(this, privateKey.toPublic.armor())),
+       endpoint: [
+-        // ...ReachableLocal.defaultEndpoints,
+         ...ReachableRelay.getDefaultEndpoints(this),
+       ],
+     )..name = 'localuser [${privateKey.keyID}]';
+@@ -185,8 +185,8 @@ class P3p {
+   }
+ 
+   /// List<Function> of all callbacks that will be called on new messages.
+-  List<void Function(P3p p3p, Message msg, UserInfo user)> onMessageCallback =
+-      [];
++  final onMessageCallback =
++      <void Function(P3p p3p, Message msg, UserInfo user)>[];
+ 
+   /// Used internally to call onMessageCallback
+   Future<void> callOnMessage(Message msg) async {
+@@ -208,8 +208,8 @@ class P3p {
+   /// However if new event arrives it will execute normally.
+   /// Avoid long blocking of events to not render your peer
+   /// unresponsive or to not have out of sync events in database.
+-  List<Future<bool> Function(P3p p3p, Event evt, UserInfo ui)> onEventCallback =
+-      [];
++  final onEventCallback =
++      <Future<bool> Function(P3p p3p, Event evt, UserInfo ui)>[];
+ 
+   /// see: onEventCallback
+   /// Used internally to call onEventCallback
+@@ -229,8 +229,8 @@ class P3p {
+   ///  - at some other points too
+   /// If you want to block file edit or intercept it you should be
+   /// using onEventCallback (in most cases)
+-  List<void Function(P3p p3p, FileStore fs, FileStoreElement fselm)>
+-      onFileStoreElementCallback = [];
++  final onFileStoreElementCallback =
++      <void Function(P3p p3p, FileStore fs, FileStoreElement fselm)>[];
+ 
+   /// see: onFileStoreElementCallback
+   void callOnFileStoreElement(FileStore fs, FileStoreElement fselm) {
+diff --git i/lib/src/publickey.dart w/lib/src/publickey.dart
+index 39ff723..6908204 100644
+--- i/lib/src/publickey.dart
++++ w/lib/src/publickey.dart
+@@ -9,6 +9,8 @@ class PublicKey {
+     required this.publickey,
+   });
+ 
++  int id = -1;
++
+   /// Create publickey from armored string
+   static Future<PublicKey?> create(
+     P3p p3p,
+@@ -24,16 +26,16 @@ class PublicKey {
+       await p3p.db.save(pubkeyret);
+       return pubkeyret;
+     } catch (e) {
+-      p3p.print(e);
++      print(e);
+     }
+     return null;
+   }
+ 
+   /// Key's fingerprint
+-  String fingerprint;
++  final String fingerprint;
+ 
+   /// armored publickey
+-  String publickey;
++  final String publickey;
+ 
+   /// encrypt for this publickey and sign by privatekey
+   Future<String> encrypt(String data, pgp.PrivateKey privatekey) async {
+diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
+index 1a1d3c7..2f1952c 100644
+--- i/lib/src/reachable/relay.dart
++++ w/lib/src/reachable/relay.dart
+@@ -46,7 +46,7 @@ class ReachableRelay implements Reachable {
+   }
+ 
+   @override
+-  List<String> protocols = ['relay', 'relays'];
++  List<String> protocols = ['relay', 'relays', 'i2p'];
+ 
+   @override
+   Future<P3pError?> reach({
+@@ -150,6 +150,8 @@ class ReachableRelay implements Reachable {
+           await generateAuth(endp, p3p.privateKey),
+         ),
+       ),
++      if (endp.protocol == 'i2p')
++        'relay-host': endp.toString().replaceAll('i2p://', 'http://'),
+     };
+   }
+ 
+diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
+index 904f4b4..563108e 100644
+--- i/lib/src/userinfo.dart
++++ w/lib/src/userinfo.dart
+@@ -1,24 +1,31 @@
+ import 'dart:convert';
+ 
++import 'package:isar/isar.dart';
+ import 'package:p3p/p3p.dart';
+ 
+ /// Information about user, together with helper functions
+ class UserInfo {
+   /// You shouldn't use this function, use UserInfo.create instead.
+   UserInfo({
+-    required this.publicKey,
++    required PublicKey? publicKey,
+     required this.endpoint,
+     this.id = -1,
+     this.name,
+-  });
++  }) {
++    if (publicKey != null) {
++      this.publicKey = publicKey;
++    }
++  }
+ 
+   /// id, -1 means insert to database as new.
+   int id = -1;
+ 
+   /// PublicKey to identify the user
+-  PublicKey publicKey;
++  @ignore // make isar happy
++  late PublicKey publicKey;
+ 
+   /// Places where we can reach given user
++  @ignore // make isar happy
+   List<Endpoint> endpoint;
+ 
+   /// User's display name, if null we will send introduce.request
+@@ -34,6 +41,7 @@ class UserInfo {
+   DateTime lastEvent = DateTime.fromMicrosecondsSinceEpoch(0);
+ 
+   /// getter for the given UserInfo's filestore
++  @ignore // make isar happy
+   FileStore get fileStore => FileStore(roomFingerprint: publicKey.fingerprint);
+ 
+   /// Get all messages and sort them based on when they got received
+@@ -68,7 +76,7 @@ class UserInfo {
+       // p3p.print('fixing endpoint by adding ReachableRelay.defaultEndpoints');
+       endpoint = ReachableRelay.getDefaultEndpoints(p3p);
+     }
+-
++    print('111');
+     // 1. Get all events
+     final evts = await p3p.db.getEvents(destinationPublicKey: publicKey);
+ 
+@@ -107,7 +115,14 @@ class UserInfo {
+             );
+           case 'i2p':
+             if (p3p.reachableI2p != null) {
+-              resp = await p3p.reachableI2p!.reach(
++              resp = await p3p.reachableI2p?.reach(
++                p3p: p3p,
++                endpoint: endp,
++                message: body,
++                publicKey: publicKey,
++              );
++            } else {
++              resp = await p3p.reachableRelay.reach(
+                 p3p: p3p,
+                 endpoint: endp,
+                 message: body,
+@@ -160,11 +175,14 @@ class UserInfo {
+   }
+ 
+   /// create new UserInfo object, with sane defaults and store it in Database
++  /// `any` can be anything that may resolve to user, for now this includes:
++  /// - Fingerprint
++  //TODO(mrcyjanek): Add some kind of fingerprint database?
+   static Future<UserInfo?> create(
+     P3p p3p,
+-    String publicKey,
++    String any,
+   ) async {
+-    final pubKey = await PublicKey.create(p3p, publicKey);
++    final pubKey = await PublicKey.create(p3p, any);
+     if (pubKey == null) return null;
+     final ui = UserInfo(
+       publicKey: pubKey,
+diff --git i/pubspec.yaml w/pubspec.yaml
+index d57c095..f99371d 100644
+--- i/pubspec.yaml
++++ w/pubspec.yaml
+@@ -12,9 +12,9 @@ dependencies:
+   dart_pg: ^1.1.5
+   dio: ^5.3.2
+   drift: ^2.11.0
++  isar: ^3.1.0+1
+   logger: ^2.0.2
+   mutex: ^3.0.1
+-  objectbox: ^2.2.0
+   path: ^1.8.3
+   rxdart: ^0.27.7
+   shelf: ^1.4.1
+@@ -25,6 +25,7 @@ dependencies:
+ dev_dependencies:
+   build_runner: ^2.4.6
+   drift_dev: ^2.11.0
++  isar_generator: ^3.1.0+1
+   lints: ^2.0.0
+   test: ^1.21.0
+-  very_good_analysis: ^5.0.0+1
+\ No newline at end of file
++  very_good_analysis: ^5.0.0+1
+no changes added to commit (use "git add" and/or "git commit -a")
+
+
+$ p3pch4t 
+
+--------
+
+On branch master
+Your branch is up to date with 'origin/master'.
+
+Changes not staged for commit:
+  (use "git add <file>..." to update what will be committed)
+  (use "git restore <file>..." to discard changes in working directory)
+	modified:   android/app/src/main/AndroidManifest.xml
+	modified:   assets/git-changes.md
+	modified:   lib/main.dart
+	modified:   lib/pages/adduser.dart
+	modified:   lib/pages/fileview.dart
+	modified:   lib/pages/landing.dart
+	modified:   lib/pages/settings.dart
+	modified:   lib/pages/webxdcfileview_android.dart
+	modified:   lib/platform_interface.dart
+	modified:   lib/service.dart
+	modified:   linux/flutter/generated_plugin_registrant.cc
+	modified:   linux/flutter/generated_plugins.cmake
+	modified:   macos/Flutter/GeneratedPluginRegistrant.swift
+	modified:   pubspec.lock
+	modified:   pubspec.yaml
+	modified:   windows/flutter/generated_plugin_registrant.cc
+	modified:   windows/flutter/generated_plugins.cmake
+
+Untracked files:
+  (use "git add <file>..." to include in what will be committed)
+	lib/pages/register.dart
+
+--------------------------------------------------
+Changes not staged for commit:
+diff --git i/android/app/src/main/AndroidManifest.xml w/android/app/src/main/AndroidManifest.xml
+index 00ff038..bd5f1a4 100644
+--- i/android/app/src/main/AndroidManifest.xml
++++ w/android/app/src/main/AndroidManifest.xml
+@@ -38,4 +38,7 @@
+     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
+     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
+     <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
++    <uses-permission android:name="android.permission.CAMERA" />
++    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
++    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
+ </manifest>
+diff --git i/assets/git-changes.md w/assets/git-changes.md
+index 3a5e193..4583310 100644
+--- i/assets/git-changes.md
++++ w/assets/git-changes.md
+@@ -1 +1,2106 @@
+ If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.
++
++
++$ p3p.dart 
++
++--------
++
++On branch master
++Your branch is up to date with 'origin/master'.
++
++Changes not staged for commit:
++  (use "git add <file>..." to update what will be committed)
++  (use "git restore <file>..." to discard changes in working directory)
++	modified:   lib/src/reachable/relay.dart
++	modified:   lib/src/userinfo.dart
++
++--------------------------------------------------
++Changes not staged for commit:
++diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
++index 1a1d3c7..2f1952c 100644
++--- i/lib/src/reachable/relay.dart
+++++ w/lib/src/reachable/relay.dart
++@@ -46,7 +46,7 @@ class ReachableRelay implements Reachable {
++   }
++ 
++   @override
++-  List<String> protocols = ['relay', 'relays'];
+++  List<String> protocols = ['relay', 'relays', 'i2p'];
++ 
++   @override
++   Future<P3pError?> reach({
++@@ -150,6 +150,8 @@ class ReachableRelay implements Reachable {
++           await generateAuth(endp, p3p.privateKey),
++         ),
++       ),
+++      if (endp.protocol == 'i2p')
+++        'relay-host': endp.toString().replaceAll('i2p://', 'http://'),
++     };
++   }
++ 
++diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
++index 904f4b4..4e5fd13 100644
++--- i/lib/src/userinfo.dart
+++++ w/lib/src/userinfo.dart
++@@ -107,7 +107,14 @@ class UserInfo {
++             );
++           case 'i2p':
++             if (p3p.reachableI2p != null) {
++-              resp = await p3p.reachableI2p!.reach(
+++              resp = await p3p.reachableI2p?.reach(
+++                p3p: p3p,
+++                endpoint: endp,
+++                message: body,
+++                publicKey: publicKey,
+++              );
+++            } else {
+++              resp = await p3p.reachableRelay.reach(
++                 p3p: p3p,
++                 endpoint: endp,
++                 message: body,
++@@ -160,11 +167,14 @@ class UserInfo {
++   }
++ 
++   /// create new UserInfo object, with sane defaults and store it in Database
+++  /// `any` can be anything that may resolve to user, for now this includes:
+++  /// - Fingerprint
+++  //TODO(mrcyjanek): Add some kind of fingerprint database?
++   static Future<UserInfo?> create(
++     P3p p3p,
++-    String publicKey,
+++    String any,
++   ) async {
++-    final pubKey = await PublicKey.create(p3p, publicKey);
+++    final pubKey = await PublicKey.create(p3p, any);
++     if (pubKey == null) return null;
++     final ui = UserInfo(
++       publicKey: pubKey,
++no changes added to commit (use "git add" and/or "git commit -a")
++
++
++$ p3pch4t 
++
++--------
++
++On branch master
++Your branch is up to date with 'origin/master'.
++
++Changes not staged for commit:
++  (use "git add <file>..." to update what will be committed)
++  (use "git restore <file>..." to discard changes in working directory)
++	modified:   android/app/src/main/AndroidManifest.xml
++	modified:   assets/git-changes.md
++	modified:   lib/main.dart
++	modified:   lib/pages/adduser.dart
++	modified:   lib/pages/landing.dart
++	modified:   lib/pages/settings.dart
++	modified:   lib/pages/webxdcfileview_android.dart
++	modified:   lib/platform_interface.dart
++	modified:   lib/service.dart
++	modified:   pubspec.lock
++	modified:   pubspec.yaml
++
++Untracked files:
++  (use "git add <file>..." to include in what will be committed)
++	lib/pages/register.dart
++
++--------------------------------------------------
++Changes not staged for commit:
++diff --git i/android/app/src/main/AndroidManifest.xml w/android/app/src/main/AndroidManifest.xml
++index 00ff038..bd5f1a4 100644
++--- i/android/app/src/main/AndroidManifest.xml
+++++ w/android/app/src/main/AndroidManifest.xml
++@@ -38,4 +38,7 @@
++     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
++     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
++     <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
+++    <uses-permission android:name="android.permission.CAMERA" />
+++    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
+++    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
++ </manifest>
++diff --git i/assets/git-changes.md w/assets/git-changes.md
++index 3a5e193..17bdbcc 100644
++--- i/assets/git-changes.md
+++++ w/assets/git-changes.md
++@@ -1 +1,1551 @@
++ If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.
+++
+++
+++$ p3p.dart 
+++
+++--------
+++
+++On branch master
+++Your branch is up to date with 'origin/master'.
+++
+++Changes not staged for commit:
+++  (use "git add <file>..." to update what will be committed)
+++  (use "git restore <file>..." to discard changes in working directory)
+++	modified:   lib/src/reachable/relay.dart
+++	modified:   lib/src/userinfo.dart
+++
+++--------------------------------------------------
+++Changes not staged for commit:
+++diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
+++index 1a1d3c7..2f1952c 100644
+++--- i/lib/src/reachable/relay.dart
++++++ w/lib/src/reachable/relay.dart
+++@@ -46,7 +46,7 @@ class ReachableRelay implements Reachable {
+++   }
+++ 
+++   @override
+++-  List<String> protocols = ['relay', 'relays'];
++++  List<String> protocols = ['relay', 'relays', 'i2p'];
+++ 
+++   @override
+++   Future<P3pError?> reach({
+++@@ -150,6 +150,8 @@ class ReachableRelay implements Reachable {
+++           await generateAuth(endp, p3p.privateKey),
+++         ),
+++       ),
++++      if (endp.protocol == 'i2p')
++++        'relay-host': endp.toString().replaceAll('i2p://', 'http://'),
+++     };
+++   }
+++ 
+++diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
+++index 904f4b4..4e5fd13 100644
+++--- i/lib/src/userinfo.dart
++++++ w/lib/src/userinfo.dart
+++@@ -107,7 +107,14 @@ class UserInfo {
+++             );
+++           case 'i2p':
+++             if (p3p.reachableI2p != null) {
+++-              resp = await p3p.reachableI2p!.reach(
++++              resp = await p3p.reachableI2p?.reach(
++++                p3p: p3p,
++++                endpoint: endp,
++++                message: body,
++++                publicKey: publicKey,
++++              );
++++            } else {
++++              resp = await p3p.reachableRelay.reach(
+++                 p3p: p3p,
+++                 endpoint: endp,
+++                 message: body,
+++@@ -160,11 +167,14 @@ class UserInfo {
+++   }
+++ 
+++   /// create new UserInfo object, with sane defaults and store it in Database
++++  /// `any` can be anything that may resolve to user, for now this includes:
++++  /// - Fingerprint
++++  //TODO(mrcyjanek): Add some kind of fingerprint database?
+++   static Future<UserInfo?> create(
+++     P3p p3p,
+++-    String publicKey,
++++    String any,
+++   ) async {
+++-    final pubKey = await PublicKey.create(p3p, publicKey);
++++    final pubKey = await PublicKey.create(p3p, any);
+++     if (pubKey == null) return null;
+++     final ui = UserInfo(
+++       publicKey: pubKey,
+++no changes added to commit (use "git add" and/or "git commit -a")
+++
+++
+++$ p3pch4t 
+++
+++--------
+++
+++On branch master
+++Your branch is up to date with 'origin/master'.
+++
+++Changes not staged for commit:
+++  (use "git add <file>..." to update what will be committed)
+++  (use "git restore <file>..." to discard changes in working directory)
+++	modified:   android/app/src/main/AndroidManifest.xml
+++	modified:   assets/git-changes.md
+++	modified:   lib/main.dart
+++	modified:   lib/pages/adduser.dart
+++	modified:   lib/pages/landing.dart
+++	modified:   lib/pages/settings.dart
+++	modified:   lib/pages/webxdcfileview_android.dart
+++	modified:   lib/platform_interface.dart
+++	modified:   lib/service.dart
+++	modified:   pubspec.lock
+++	modified:   pubspec.yaml
+++
+++Untracked files:
+++  (use "git add <file>..." to include in what will be committed)
+++	lib/pages/register.dart
+++
+++--------------------------------------------------
+++Changes not staged for commit:
+++diff --git i/android/app/src/main/AndroidManifest.xml w/android/app/src/main/AndroidManifest.xml
+++index 00ff038..bd5f1a4 100644
+++--- i/android/app/src/main/AndroidManifest.xml
++++++ w/android/app/src/main/AndroidManifest.xml
+++@@ -38,4 +38,7 @@
+++     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
+++     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
+++     <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
++++    <uses-permission android:name="android.permission.CAMERA" />
++++    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
++++    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
+++ </manifest>
+++diff --git i/assets/git-changes.md w/assets/git-changes.md
+++index 3a5e193..7ea60f4 100644
+++--- i/assets/git-changes.md
++++++ w/assets/git-changes.md
+++@@ -1 +1,1019 @@
+++ If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.
++++
++++
++++$ p3p.dart 
++++
++++--------
++++
++++On branch master
++++Your branch is up to date with 'origin/master'.
++++
++++Changes not staged for commit:
++++  (use "git add <file>..." to update what will be committed)
++++  (use "git restore <file>..." to discard changes in working directory)
++++	modified:   lib/src/reachable/relay.dart
++++	modified:   lib/src/userinfo.dart
++++
++++--------------------------------------------------
++++Changes not staged for commit:
++++diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
++++index 1a1d3c7..2f1952c 100644
++++--- i/lib/src/reachable/relay.dart
+++++++ w/lib/src/reachable/relay.dart
++++@@ -46,7 +46,7 @@ class ReachableRelay implements Reachable {
++++   }
++++ 
++++   @override
++++-  List<String> protocols = ['relay', 'relays'];
+++++  List<String> protocols = ['relay', 'relays', 'i2p'];
++++ 
++++   @override
++++   Future<P3pError?> reach({
++++@@ -150,6 +150,8 @@ class ReachableRelay implements Reachable {
++++           await generateAuth(endp, p3p.privateKey),
++++         ),
++++       ),
+++++      if (endp.protocol == 'i2p')
+++++        'relay-host': endp.toString().replaceAll('i2p://', 'http://'),
++++     };
++++   }
++++ 
++++diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
++++index 904f4b4..4e5fd13 100644
++++--- i/lib/src/userinfo.dart
+++++++ w/lib/src/userinfo.dart
++++@@ -107,7 +107,14 @@ class UserInfo {
++++             );
++++           case 'i2p':
++++             if (p3p.reachableI2p != null) {
++++-              resp = await p3p.reachableI2p!.reach(
+++++              resp = await p3p.reachableI2p?.reach(
+++++                p3p: p3p,
+++++                endpoint: endp,
+++++                message: body,
+++++                publicKey: publicKey,
+++++              );
+++++            } else {
+++++              resp = await p3p.reachableRelay.reach(
++++                 p3p: p3p,
++++                 endpoint: endp,
++++                 message: body,
++++@@ -160,11 +167,14 @@ class UserInfo {
++++   }
++++ 
++++   /// create new UserInfo object, with sane defaults and store it in Database
+++++  /// `any` can be anything that may resolve to user, for now this includes:
+++++  /// - Fingerprint
+++++  //TODO(mrcyjanek): Add some kind of fingerprint database?
++++   static Future<UserInfo?> create(
++++     P3p p3p,
++++-    String publicKey,
+++++    String any,
++++   ) async {
++++-    final pubKey = await PublicKey.create(p3p, publicKey);
+++++    final pubKey = await PublicKey.create(p3p, any);
++++     if (pubKey == null) return null;
++++     final ui = UserInfo(
++++       publicKey: pubKey,
++++no changes added to commit (use "git add" and/or "git commit -a")
++++
++++
++++$ p3pch4t 
++++
++++--------
++++
++++On branch master
++++Your branch is up to date with 'origin/master'.
++++
++++Changes not staged for commit:
++++  (use "git add <file>..." to update what will be committed)
++++  (use "git restore <file>..." to discard changes in working directory)
++++	modified:   android/app/src/main/AndroidManifest.xml
++++	modified:   assets/git-changes.md
++++	modified:   lib/main.dart
++++	modified:   lib/pages/adduser.dart
++++	modified:   lib/pages/landing.dart
++++	modified:   lib/pages/settings.dart
++++	modified:   lib/pages/webxdcfileview_android.dart
++++	modified:   lib/platform_interface.dart
++++	modified:   lib/service.dart
++++	modified:   pubspec.lock
++++	modified:   pubspec.yaml
++++
++++Untracked files:
++++  (use "git add <file>..." to include in what will be committed)
++++	lib/pages/register.dart
++++
++++--------------------------------------------------
++++Changes not staged for commit:
++++diff --git i/android/app/src/main/AndroidManifest.xml w/android/app/src/main/AndroidManifest.xml
++++index 00ff038..bd5f1a4 100644
++++--- i/android/app/src/main/AndroidManifest.xml
+++++++ w/android/app/src/main/AndroidManifest.xml
++++@@ -38,4 +38,7 @@
++++     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
++++     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
++++     <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
+++++    <uses-permission android:name="android.permission.CAMERA" />
+++++    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
+++++    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
++++ </manifest>
++++diff --git i/assets/git-changes.md w/assets/git-changes.md
++++index 3a5e193..3a8a5a6 100644
++++--- i/assets/git-changes.md
+++++++ w/assets/git-changes.md
++++@@ -1 +1,496 @@
++++ If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.
+++++
+++++
+++++$ p3p.dart 
+++++
+++++--------
+++++
+++++On branch master
+++++Your branch is up to date with 'origin/master'.
+++++
+++++Changes not staged for commit:
+++++  (use "git add <file>..." to update what will be committed)
+++++  (use "git restore <file>..." to discard changes in working directory)
+++++	modified:   lib/src/reachable/relay.dart
+++++	modified:   lib/src/userinfo.dart
+++++
+++++--------------------------------------------------
+++++Changes not staged for commit:
+++++diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
+++++index 1a1d3c7..2f1952c 100644
+++++--- i/lib/src/reachable/relay.dart
++++++++ w/lib/src/reachable/relay.dart
+++++@@ -46,7 +46,7 @@ class ReachableRelay implements Reachable {
+++++   }
+++++ 
+++++   @override
+++++-  List<String> protocols = ['relay', 'relays'];
++++++  List<String> protocols = ['relay', 'relays', 'i2p'];
+++++ 
+++++   @override
+++++   Future<P3pError?> reach({
+++++@@ -150,6 +150,8 @@ class ReachableRelay implements Reachable {
+++++           await generateAuth(endp, p3p.privateKey),
+++++         ),
+++++       ),
++++++      if (endp.protocol == 'i2p')
++++++        'relay-host': endp.toString().replaceAll('i2p://', 'http://'),
+++++     };
+++++   }
+++++ 
+++++diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
+++++index 904f4b4..4e5fd13 100644
+++++--- i/lib/src/userinfo.dart
++++++++ w/lib/src/userinfo.dart
+++++@@ -107,7 +107,14 @@ class UserInfo {
+++++             );
+++++           case 'i2p':
+++++             if (p3p.reachableI2p != null) {
+++++-              resp = await p3p.reachableI2p!.reach(
++++++              resp = await p3p.reachableI2p?.reach(
++++++                p3p: p3p,
++++++                endpoint: endp,
++++++                message: body,
++++++                publicKey: publicKey,
++++++              );
++++++            } else {
++++++              resp = await p3p.reachableRelay.reach(
+++++                 p3p: p3p,
+++++                 endpoint: endp,
+++++                 message: body,
+++++@@ -160,11 +167,14 @@ class UserInfo {
+++++   }
+++++ 
+++++   /// create new UserInfo object, with sane defaults and store it in Database
++++++  /// `any` can be anything that may resolve to user, for now this includes:
++++++  /// - Fingerprint
++++++  //TODO(mrcyjanek): Add some kind of fingerprint database?
+++++   static Future<UserInfo?> create(
+++++     P3p p3p,
+++++-    String publicKey,
++++++    String any,
+++++   ) async {
+++++-    final pubKey = await PublicKey.create(p3p, publicKey);
++++++    final pubKey = await PublicKey.create(p3p, any);
+++++     if (pubKey == null) return null;
+++++     final ui = UserInfo(
+++++       publicKey: pubKey,
+++++no changes added to commit (use "git add" and/or "git commit -a")
+++++
+++++
+++++$ p3pch4t 
+++++
+++++--------
+++++
+++++On branch master
+++++Your branch is up to date with 'origin/master'.
+++++
+++++Changes not staged for commit:
+++++  (use "git add <file>..." to update what will be committed)
+++++  (use "git restore <file>..." to discard changes in working directory)
+++++	modified:   android/app/src/main/AndroidManifest.xml
+++++	modified:   lib/main.dart
+++++	modified:   lib/pages/adduser.dart
+++++	modified:   lib/pages/landing.dart
+++++	modified:   lib/pages/settings.dart
+++++	modified:   lib/pages/webxdcfileview_android.dart
+++++	modified:   lib/platform_interface.dart
+++++	modified:   lib/service.dart
+++++	modified:   pubspec.lock
+++++	modified:   pubspec.yaml
+++++
+++++Untracked files:
+++++  (use "git add <file>..." to include in what will be committed)
+++++	lib/pages/register.dart
+++++
+++++--------------------------------------------------
+++++Changes not staged for commit:
+++++diff --git i/android/app/src/main/AndroidManifest.xml w/android/app/src/main/AndroidManifest.xml
+++++index 00ff038..bd5f1a4 100644
+++++--- i/android/app/src/main/AndroidManifest.xml
++++++++ w/android/app/src/main/AndroidManifest.xml
+++++@@ -38,4 +38,7 @@
+++++     <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
+++++     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
+++++     <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
++++++    <uses-permission android:name="android.permission.CAMERA" />
++++++    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
++++++    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
+++++ </manifest>
+++++diff --git i/lib/main.dart w/lib/main.dart
+++++index 43574e7..6dda900 100644
+++++--- i/lib/main.dart
++++++++ w/lib/main.dart
+++++@@ -8,6 +8,7 @@ import 'package:p3p/p3p.dart';
+++++ import 'package:p3pch4t/consts.dart';
+++++ import 'package:p3pch4t/pages/home.dart';
+++++ import 'package:p3pch4t/pages/landing.dart';
++++++import 'package:p3pch4t/platform_interface.dart';
+++++ import 'package:p3pch4t/service.dart';
+++++ import 'package:permission_handler/permission_handler.dart';
+++++ import 'package:shared_preferences/shared_preferences.dart';
+++++@@ -17,6 +18,10 @@ P3p? p3p;
+++++ 
+++++ void main() async {
+++++   WidgetsFlutterBinding.ensureInitialized();
++++++  // we need to call it here because otherwise it may not store information
++++++  // about path used in the SharedPreferences - that will lead to I2pdEnsure
++++++  // (and possibly others) being unable to find the path.
++++++  await getAndroidNativeLibraryDirectory(forceRefresh: true);
+++++   final prefs = await SharedPreferences.getInstance();
+++++   if (prefs.getString('priv_key') == null) {
+++++     runApp(
+++++diff --git i/lib/pages/adduser.dart w/lib/pages/adduser.dart
+++++index 74b7e16..a2ee05c 100644
+++++--- i/lib/pages/adduser.dart
++++++++ w/lib/pages/adduser.dart
+++++@@ -1,9 +1,14 @@
+++++ // ignore_for_file: public_member_api_docs
+++++ 
++++++import 'dart:async';
++++++import 'dart:math';
++++++
+++++ import 'package:flutter/material.dart';
+++++ import 'package:p3p/p3p.dart';
+++++ import 'package:p3pch4t/helpers.dart';
+++++ import 'package:p3pch4t/main.dart';
++++++import 'package:qr_flutter/qr_flutter.dart';
++++++import 'package:qrscan/qrscan.dart' as scanner;
+++++ 
+++++ class AddUserPage extends StatefulWidget {
+++++   const AddUserPage({super.key});
+++++@@ -37,33 +42,72 @@ class _AddUserPageState extends State<AddUserPage> {
+++++       body: SingleChildScrollView(
+++++         child: Column(
+++++           children: [
+++++-            SelectableText('FP: ${selfUi!.publicKey.fingerprint}'),
+++++-            SelectableText(
+++++-              selfUi!.publicKey.publickey,
+++++-              style: const TextStyle(fontSize: 7),
+++++-            ),
++++++            SelectableText(selfUi!.publicKey.fingerprint),
+++++             TextField(
+++++               controller: pkCtrl,
+++++-              maxLines: 16,
+++++-              minLines: 16,
++++++              minLines: 1,
+++++               decoration: const InputDecoration(
+++++                 border: OutlineInputBorder(),
+++++               ),
+++++             ),
+++++-            OutlinedButton(
+++++-              onPressed: () async {
+++++-                final ui = await UserInfo.create(p3p!, pkCtrl.text);
+++++-                if (ui == null) {
+++++-                  return;
+++++-                }
+++++-                if (!mounted) return;
+++++-                Navigator.of(context).pop();
+++++-              },
+++++-              child: const Text('Add'),
++++++            SizedBox(
++++++              width: double.maxFinite,
++++++              child: ElevatedButton(
++++++                onPressed: () async {
++++++                  final ui = await UserInfo.create(p3p!, pkCtrl.text);
++++++                  if (ui == null) {
++++++                    return;
++++++                  }
++++++                  if (!mounted) return;
++++++                  Navigator.of(context).pop();
++++++                },
++++++                child: const Text('Add'),
++++++              ),
+++++             ),
++++++            URQR(text: selfUi!.publicKey.publickey),
+++++           ],
+++++         ),
+++++       ),
+++++     );
+++++   }
+++++ }
++++++
++++++class URQR extends StatefulWidget {
++++++  const URQR({required this.text, super.key});
++++++
++++++  final String text;
++++++
++++++  @override
++++++  _URQRState createState() => _URQRState();
++++++}
++++++
++++++class _URQRState extends State<URQR> {
++++++  late List<String> texts;
++++++  final int divider = 500;
++++++  @override
++++++  void initState() {
++++++    final tmpList = <String>[];
++++++    for (var i = 0; i < widget.text.length; i++) {
++++++      if (i % divider == 0) {
++++++        final tempString =
++++++            widget.text.substring(i, min(i + divider, widget.text.length));
++++++        tmpList.add(tempString);
++++++      }
++++++    }
++++++    setState(() {
++++++      texts = tmpList;
++++++    });
++++++    Timer.periodic(const Duration(milliseconds: 300), (timer) {
++++++      setState(() {
++++++        i = (i + 1) % texts.length;
++++++      });
++++++    });
++++++    super.initState();
++++++  }
++++++
++++++  int i = 0;
++++++  @override
++++++  Widget build(BuildContext context) {
++++++    return QrImageView(data: '$i/${texts[i].length}|${texts[i]}');
++++++  }
++++++}
+++++diff --git i/lib/pages/landing.dart w/lib/pages/landing.dart
+++++index 90df48f..178b12e 100644
+++++--- i/lib/pages/landing.dart
++++++++ w/lib/pages/landing.dart
+++++@@ -6,6 +6,7 @@ import 'package:dart_pg/dart_pg.dart';
+++++ import 'package:flutter/material.dart';
+++++ import 'package:p3pch4t/helpers.dart';
+++++ import 'package:p3pch4t/pages/home.dart';
++++++import 'package:p3pch4t/pages/register.dart';
+++++ import 'package:p3pch4t/service.dart';
+++++ import 'package:permission_handler/permission_handler.dart';
+++++ import 'package:shared_preferences/shared_preferences.dart';
+++++@@ -49,34 +50,11 @@ class _LandingPageState extends State<LandingPage> {
+++++               const Spacer(),
+++++               OutlinedButton(
+++++                 onPressed: () async {
+++++-                  setState(() {
+++++-                    isLoading = true;
+++++-                  });
+++++-                  final prefs = await SharedPreferences.getInstance();
+++++-
+++++-                  debugPrint('generating privkey...');
+++++-                  final privkey = await OpenPGP.generateKey(
+++++-                    ['name <user@example.org>'],
+++++-                    'no_passpharse',
+++++-                  );
+++++-                  await prefs.setString('priv_key', privkey.armor());
+++++-                  setState(() {
+++++-                    isLoading = false;
+++++-                  });
+++++-                  if (!mounted) {
+++++-                    await Future<void>.delayed(const Duration(seconds: 1));
+++++-                    exit(1);
+++++-                  }
+++++-                  if (Platform.isAndroid) {
+++++-                    await Permission.notification.request();
+++++-                  }
+++++-                  await initializeService();
+++++-                  if (mounted) return;
+++++                   // it is used safely here.
+++++                   // ignore: use_build_context_synchronously
+++++                   await Navigator.of(context).pushReplacement(
+++++                     MaterialPageRoute<void>(
+++++-                      builder: (context) => const HomePage(),
++++++                      builder: (context) => const RegisterPage(),
+++++                     ),
+++++                   );
+++++                 },
+++++diff --git i/lib/pages/settings.dart w/lib/pages/settings.dart
+++++index deebc0f..c62f9dc 100644
+++++--- i/lib/pages/settings.dart
++++++++ w/lib/pages/settings.dart
+++++@@ -1,5 +1,6 @@
+++++ // ignore_for_file: public_member_api_docs
+++++ 
++++++import 'package:flutter/foundation.dart';
+++++ import 'package:flutter/material.dart';
+++++ import 'package:flutter_i2p/flutter_i2p.dart';
+++++ import 'package:p3pch4t/main.dart';
+++++diff --git i/lib/pages/webxdcfileview_android.dart w/lib/pages/webxdcfileview_android.dart
+++++index e861d55..828cb46 100644
+++++--- i/lib/pages/webxdcfileview_android.dart
++++++++ w/lib/pages/webxdcfileview_android.dart
+++++@@ -78,8 +78,12 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
+++++         // I/flutter (14004):     "descr": "localuser scored 25 in Tower Builder!"
+++++         // I/flutter (14004): }
+++++         if (kDebugMode) print('p3p_native_sendUpdate:');
++++++        // p0.message is what we receive from the browser
+++++         final jBody = json.decode(p0.message) as Map<String, dynamic>;
++++++        // what is interesting for us is the "update" field, as can be seen in
++++++        // comment above.
+++++         final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
++++++        // 'info' field, according to WebXDC field should be sent to the room.
+++++         if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
+++++           await p3p!.sendMessage(
+++++             widget.chatroom,
+++++@@ -90,25 +94,33 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
+++++         // append the update to update file.
+++++         final updateElm = await getUpdateElement();
+++++         if (updateElm == null) {
++++++          // We don't have the .jsonp file - despite the fact that it was
++++++          // created.
+++++           if (mounted) Navigator.of(context).pop();
+++++           return;
+++++         }
+++++ 
++++++        // For whatever reason I'd love to use microseconds, because idk
++++++        // but I can't because JS.
++++++        final timestamp = DateTime.now().millisecondsSinceEpoch;
+++++         await updateElm.file.writeAsString(
+++++-          "\n${json.encode(jBodyUpdate["payload"])}",
++++++          "\n$timestamp:${json.encode(jBodyUpdate["payload"])}",
+++++           mode: FileMode.append,
+++++           flush: true,
+++++         );
+++++-        final lines = await updateElm.file.readAsLines();
++++++
+++++         await updateElm.updateContent(
+++++           p3p!,
+++++         );
+++++         final jsPayload = '''
+++++ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
+++++   window.webxdc.setUpdateListenerList[i]({
++++++    // NOTE: Is it possible to exploit this somehow?
++++++    // talking about the dart side of things.
++++++    // I'm sorry for you if you had to dig here from JS world.
+++++     "payload": ${json.encode(jBodyUpdate["payload"])},
+++++-    "serial": ${lines.length},
+++++-    "max_serial": ${lines.length},
++++++    "serial": $timestamp,
++++++    "max_serial": $timestamp,
+++++     "info": null,
+++++     "document": null,
+++++     "summary": null,
+++++@@ -141,16 +153,21 @@ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
+++++           return;
+++++         }
+++++         final lines = updateElm.file.readAsLinesSync();
++++++        final regexp = RegExp('/^[0-9]+:/gm');
+++++         for (var i = 0; i < lines.length; i++) {
++++++          final match = regexp.stringMatch(lines[i]);
++++++          if (match == null) continue;
++++++          final matchInt = match.replaceAll(':', '');
+++++           try {
+++++-            final payload = json.encode(json.decode(lines[i]));
++++++            final payload =
++++++                json.encode(json.decode(lines[i].substring(match.length)));
+++++             final jsPayload = '''
+++++ console.log("setUpdateListener: hook id: $i");
+++++ 
+++++ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+++++   "payload": $payload,
+++++-  "serial": $i,
+++++-  "max_serial": ${lines.length},
++++++  "serial": $matchInt,
++++++  "max_serial": $matchInt,
+++++   "info": null,
+++++   "document": null,
+++++   "summary": null,
+++++@@ -210,7 +227,7 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+++++     final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
+++++     final wpath = widget.webxdcFile.path;
+++++     final desiredPath = p.normalize(
+++++-      (wpath.split('/')
++++++      (wpath.split(Platform.isWindows ? r'\' : '/')
+++++             ..removeLast()
+++++             ..add('.${p.basename(wpath)}.update.jsonp'))
+++++           .join('/'),
+++++diff --git i/lib/platform_interface.dart w/lib/platform_interface.dart
+++++index eeb2cba..32772f3 100644
+++++--- i/lib/platform_interface.dart
++++++++ w/lib/platform_interface.dart
+++++@@ -9,20 +9,23 @@ const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');
+++++ Future<Directory> getAndroidNativeLibraryDirectory({
+++++   bool forceRefresh = false,
+++++ }) async {
++++++  var state = 'prefs';
+++++   final prefs = await SharedPreferences.getInstance();
+++++   var nldir =
+++++       prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');
+++++ 
+++++   if (nldir == null || forceRefresh) {
++++++    state = 'firstif';
+++++     nldir = await _platform
+++++         .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
+++++     if (nldir != null) {
++++++      state = 'secondif';
+++++       await prefs.setString(
+++++         'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
+++++         nldir,
+++++       );
+++++     }
+++++   }
+++++-  if (nldir == null) return Directory('/non_existent');
++++++  if (nldir == null) return Directory('/non_existent/$state');
+++++   return Directory(nldir);
+++++ }
+++++diff --git i/lib/service.dart w/lib/service.dart
+++++index 948dac1..c52f674 100644
+++++--- i/lib/service.dart
++++++++ w/lib/service.dart
+++++@@ -302,7 +302,7 @@ Future<void> startP3p({
+++++ Future<String> getBinPath() async {
+++++   switch (getPlatform()) {
+++++     case OS.android:
+++++-      (await getAndroidNativeLibraryDirectory()).path;
++++++      return (await getAndroidNativeLibraryDirectory()).path;
+++++ 
+++++     case _:
+++++       final prefs = await SharedPreferences.getInstance();
+++++@@ -315,5 +315,4 @@ Future<String> getBinPath() async {
+++++         _ => p.join((await getApplicationSupportDirectory()).path, 'bin'),
+++++       };
+++++   }
+++++-  return '/non_existent';
+++++ }
+++++diff --git i/pubspec.lock w/pubspec.lock
+++++index 37758b1..85e6f5e 100644
+++++--- i/pubspec.lock
++++++++ w/pubspec.lock
+++++@@ -565,6 +565,30 @@ packages:
+++++       url: "https://pub.dev"
+++++     source: hosted
+++++     version: "3.7.3"
++++++  qr:
++++++    dependency: transitive
++++++    description:
++++++      name: qr
++++++      sha256: "64957a3930367bf97cc211a5af99551d630f2f4625e38af10edd6b19131b64b3"
++++++      url: "https://pub.dev"
++++++    source: hosted
++++++    version: "3.0.1"
++++++  qr_flutter:
++++++    dependency: "direct main"
++++++    description:
++++++      name: qr_flutter
++++++      sha256: "5095f0fc6e3f71d08adef8feccc8cea4f12eec18a2e31c2e8d82cb6019f4b097"
++++++      url: "https://pub.dev"
++++++    source: hosted
++++++    version: "4.1.0"
++++++  qrscan:
++++++    dependency: "direct main"
++++++    description:
++++++      name: qrscan
++++++      sha256: "0ee72eca0dcbc35ab74894010e3589c3675ddb7c5a551d5f29ab0d3bb1bfb135"
++++++      url: "https://pub.dev"
++++++    source: hosted
++++++    version: "0.3.3"
+++++   quiver:
+++++     dependency: transitive
+++++     description:
+++++diff --git i/pubspec.yaml w/pubspec.yaml
+++++index c9c2ef9..46e3f44 100644
+++++--- i/pubspec.yaml
++++++++ w/pubspec.yaml
+++++@@ -31,6 +31,8 @@ dependencies:
+++++   path: ^1.8.3
+++++   path_provider: ^2.1.0
+++++   permission_handler: ^10.4.3
++++++  qr_flutter: ^4.1.0
++++++  qrscan: ^0.3.3
+++++   shared_preferences: ^2.2.0
+++++   shelf: ^1.4.1
+++++   sqlite3_flutter_libs: ^0.5.0
+++++no changes added to commit (use "git add" and/or "git commit -a")
++++diff --git i/lib/main.dart w/lib/main.dart
++++index 43574e7..6dda900 100644
++++--- i/lib/main.dart
+++++++ w/lib/main.dart
++++@@ -8,6 +8,7 @@ import 'package:p3p/p3p.dart';
++++ import 'package:p3pch4t/consts.dart';
++++ import 'package:p3pch4t/pages/home.dart';
++++ import 'package:p3pch4t/pages/landing.dart';
+++++import 'package:p3pch4t/platform_interface.dart';
++++ import 'package:p3pch4t/service.dart';
++++ import 'package:permission_handler/permission_handler.dart';
++++ import 'package:shared_preferences/shared_preferences.dart';
++++@@ -17,6 +18,10 @@ P3p? p3p;
++++ 
++++ void main() async {
++++   WidgetsFlutterBinding.ensureInitialized();
+++++  // we need to call it here because otherwise it may not store information
+++++  // about path used in the SharedPreferences - that will lead to I2pdEnsure
+++++  // (and possibly others) being unable to find the path.
+++++  await getAndroidNativeLibraryDirectory(forceRefresh: true);
++++   final prefs = await SharedPreferences.getInstance();
++++   if (prefs.getString('priv_key') == null) {
++++     runApp(
++++diff --git i/lib/pages/adduser.dart w/lib/pages/adduser.dart
++++index 74b7e16..8dfdf7c 100644
++++--- i/lib/pages/adduser.dart
+++++++ w/lib/pages/adduser.dart
++++@@ -1,9 +1,15 @@
++++ // ignore_for_file: public_member_api_docs
++++ 
+++++import 'dart:async';
+++++import 'dart:math';
+++++
++++ import 'package:flutter/material.dart';
++++ import 'package:p3p/p3p.dart';
++++ import 'package:p3pch4t/helpers.dart';
++++ import 'package:p3pch4t/main.dart';
+++++import 'package:permission_handler/permission_handler.dart';
+++++import 'package:qr_flutter/qr_flutter.dart';
+++++import 'package:qrscan/qrscan.dart' as scanner;
++++ 
++++ class AddUserPage extends StatefulWidget {
++++   const AddUserPage({super.key});
++++@@ -37,33 +43,92 @@ class _AddUserPageState extends State<AddUserPage> {
++++       body: SingleChildScrollView(
++++         child: Column(
++++           children: [
++++-            SelectableText('FP: ${selfUi!.publicKey.fingerprint}'),
++++-            SelectableText(
++++-              selfUi!.publicKey.publickey,
++++-              style: const TextStyle(fontSize: 7),
++++-            ),
+++++            SelectableText(selfUi!.publicKey.fingerprint),
++++             TextField(
++++               controller: pkCtrl,
++++-              maxLines: 16,
++++-              minLines: 16,
+++++              minLines: 1,
++++               decoration: const InputDecoration(
++++                 border: OutlineInputBorder(),
++++               ),
++++             ),
++++-            OutlinedButton(
++++-              onPressed: () async {
++++-                final ui = await UserInfo.create(p3p!, pkCtrl.text);
++++-                if (ui == null) {
++++-                  return;
++++-                }
++++-                if (!mounted) return;
++++-                Navigator.of(context).pop();
++++-              },
++++-              child: const Text('Add'),
+++++            SizedBox(
+++++              width: double.maxFinite,
+++++              child: ElevatedButton(
+++++                onPressed: () async {
+++++                  final ui = await UserInfo.create(p3p!, pkCtrl.text);
+++++                  if (ui == null) {
+++++                    return;
+++++                  }
+++++                  if (!mounted) return;
+++++                  Navigator.of(context).pop();
+++++                },
+++++                child: const Text('Add'),
+++++              ),
+++++            ),
+++++            URQR(text: selfUi!.publicKey.publickey),
+++++            SizedBox(
+++++              width: double.maxFinite,
+++++              child: ElevatedButton.icon(
+++++                onPressed: scan,
+++++                icon: const Icon(Icons.camera),
+++++                label: const Text('Scan'),
+++++              ),
++++             ),
++++           ],
++++         ),
++++       ),
++++     );
++++   }
+++++
+++++  Future<void> scan() async {
+++++    await Permission.camera.request();
+++++    while (true) {
+++++      final cameraScanResult = await scanner.scan();
+++++      print(cameraScanResult);
+++++      if (cameraScanResult == null) break;
+++++    }
+++++  }
+++++}
+++++
+++++class URQR extends StatefulWidget {
+++++  const URQR({required this.text, super.key});
+++++
+++++  final String text;
+++++
+++++  @override
+++++  _URQRState createState() => _URQRState();
+++++}
+++++
+++++class _URQRState extends State<URQR> {
+++++  late List<String> texts;
+++++  final int divider = 500;
+++++  @override
+++++  void initState() {
+++++    final tmpList = <String>[];
+++++    for (var i = 0; i < widget.text.length; i++) {
+++++      if (i % divider == 0) {
+++++        final tempString =
+++++            widget.text.substring(i, min(i + divider, widget.text.length));
+++++        tmpList.add(tempString);
+++++      }
+++++    }
+++++    setState(() {
+++++      texts = tmpList;
+++++    });
+++++    Timer.periodic(const Duration(milliseconds: 300), (timer) {
+++++      setState(() {
+++++        i = (i + 1) % texts.length;
+++++      });
+++++    });
+++++    super.initState();
+++++  }
+++++
+++++  int i = 0;
+++++  @override
+++++  Widget build(BuildContext context) {
+++++    return QrImageView(
+++++      data: '$i/${texts.length}|${texts[i]}',
+++++      backgroundColor: Colors.white,
+++++    );
+++++  }
++++ }
++++diff --git i/lib/pages/landing.dart w/lib/pages/landing.dart
++++index 90df48f..178b12e 100644
++++--- i/lib/pages/landing.dart
+++++++ w/lib/pages/landing.dart
++++@@ -6,6 +6,7 @@ import 'package:dart_pg/dart_pg.dart';
++++ import 'package:flutter/material.dart';
++++ import 'package:p3pch4t/helpers.dart';
++++ import 'package:p3pch4t/pages/home.dart';
+++++import 'package:p3pch4t/pages/register.dart';
++++ import 'package:p3pch4t/service.dart';
++++ import 'package:permission_handler/permission_handler.dart';
++++ import 'package:shared_preferences/shared_preferences.dart';
++++@@ -49,34 +50,11 @@ class _LandingPageState extends State<LandingPage> {
++++               const Spacer(),
++++               OutlinedButton(
++++                 onPressed: () async {
++++-                  setState(() {
++++-                    isLoading = true;
++++-                  });
++++-                  final prefs = await SharedPreferences.getInstance();
++++-
++++-                  debugPrint('generating privkey...');
++++-                  final privkey = await OpenPGP.generateKey(
++++-                    ['name <user@example.org>'],
++++-                    'no_passpharse',
++++-                  );
++++-                  await prefs.setString('priv_key', privkey.armor());
++++-                  setState(() {
++++-                    isLoading = false;
++++-                  });
++++-                  if (!mounted) {
++++-                    await Future<void>.delayed(const Duration(seconds: 1));
++++-                    exit(1);
++++-                  }
++++-                  if (Platform.isAndroid) {
++++-                    await Permission.notification.request();
++++-                  }
++++-                  await initializeService();
++++-                  if (mounted) return;
++++                   // it is used safely here.
++++                   // ignore: use_build_context_synchronously
++++                   await Navigator.of(context).pushReplacement(
++++                     MaterialPageRoute<void>(
++++-                      builder: (context) => const HomePage(),
+++++                      builder: (context) => const RegisterPage(),
++++                     ),
++++                   );
++++                 },
++++diff --git i/lib/pages/settings.dart w/lib/pages/settings.dart
++++index deebc0f..c62f9dc 100644
++++--- i/lib/pages/settings.dart
+++++++ w/lib/pages/settings.dart
++++@@ -1,5 +1,6 @@
++++ // ignore_for_file: public_member_api_docs
++++ 
+++++import 'package:flutter/foundation.dart';
++++ import 'package:flutter/material.dart';
++++ import 'package:flutter_i2p/flutter_i2p.dart';
++++ import 'package:p3pch4t/main.dart';
++++diff --git i/lib/pages/webxdcfileview_android.dart w/lib/pages/webxdcfileview_android.dart
++++index e861d55..828cb46 100644
++++--- i/lib/pages/webxdcfileview_android.dart
+++++++ w/lib/pages/webxdcfileview_android.dart
++++@@ -78,8 +78,12 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
++++         // I/flutter (14004):     "descr": "localuser scored 25 in Tower Builder!"
++++         // I/flutter (14004): }
++++         if (kDebugMode) print('p3p_native_sendUpdate:');
+++++        // p0.message is what we receive from the browser
++++         final jBody = json.decode(p0.message) as Map<String, dynamic>;
+++++        // what is interesting for us is the "update" field, as can be seen in
+++++        // comment above.
++++         final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
+++++        // 'info' field, according to WebXDC field should be sent to the room.
++++         if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
++++           await p3p!.sendMessage(
++++             widget.chatroom,
++++@@ -90,25 +94,33 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
++++         // append the update to update file.
++++         final updateElm = await getUpdateElement();
++++         if (updateElm == null) {
+++++          // We don't have the .jsonp file - despite the fact that it was
+++++          // created.
++++           if (mounted) Navigator.of(context).pop();
++++           return;
++++         }
++++ 
+++++        // For whatever reason I'd love to use microseconds, because idk
+++++        // but I can't because JS.
+++++        final timestamp = DateTime.now().millisecondsSinceEpoch;
++++         await updateElm.file.writeAsString(
++++-          "\n${json.encode(jBodyUpdate["payload"])}",
+++++          "\n$timestamp:${json.encode(jBodyUpdate["payload"])}",
++++           mode: FileMode.append,
++++           flush: true,
++++         );
++++-        final lines = await updateElm.file.readAsLines();
+++++
++++         await updateElm.updateContent(
++++           p3p!,
++++         );
++++         final jsPayload = '''
++++ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
++++   window.webxdc.setUpdateListenerList[i]({
+++++    // NOTE: Is it possible to exploit this somehow?
+++++    // talking about the dart side of things.
+++++    // I'm sorry for you if you had to dig here from JS world.
++++     "payload": ${json.encode(jBodyUpdate["payload"])},
++++-    "serial": ${lines.length},
++++-    "max_serial": ${lines.length},
+++++    "serial": $timestamp,
+++++    "max_serial": $timestamp,
++++     "info": null,
++++     "document": null,
++++     "summary": null,
++++@@ -141,16 +153,21 @@ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
++++           return;
++++         }
++++         final lines = updateElm.file.readAsLinesSync();
+++++        final regexp = RegExp('/^[0-9]+:/gm');
++++         for (var i = 0; i < lines.length; i++) {
+++++          final match = regexp.stringMatch(lines[i]);
+++++          if (match == null) continue;
+++++          final matchInt = match.replaceAll(':', '');
++++           try {
++++-            final payload = json.encode(json.decode(lines[i]));
+++++            final payload =
+++++                json.encode(json.decode(lines[i].substring(match.length)));
++++             final jsPayload = '''
++++ console.log("setUpdateListener: hook id: $i");
++++ 
++++ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
++++   "payload": $payload,
++++-  "serial": $i,
++++-  "max_serial": ${lines.length},
+++++  "serial": $matchInt,
+++++  "max_serial": $matchInt,
++++   "info": null,
++++   "document": null,
++++   "summary": null,
++++@@ -210,7 +227,7 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
++++     final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
++++     final wpath = widget.webxdcFile.path;
++++     final desiredPath = p.normalize(
++++-      (wpath.split('/')
+++++      (wpath.split(Platform.isWindows ? r'\' : '/')
++++             ..removeLast()
++++             ..add('.${p.basename(wpath)}.update.jsonp'))
++++           .join('/'),
++++diff --git i/lib/platform_interface.dart w/lib/platform_interface.dart
++++index eeb2cba..32772f3 100644
++++--- i/lib/platform_interface.dart
+++++++ w/lib/platform_interface.dart
++++@@ -9,20 +9,23 @@ const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');
++++ Future<Directory> getAndroidNativeLibraryDirectory({
++++   bool forceRefresh = false,
++++ }) async {
+++++  var state = 'prefs';
++++   final prefs = await SharedPreferences.getInstance();
++++   var nldir =
++++       prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');
++++ 
++++   if (nldir == null || forceRefresh) {
+++++    state = 'firstif';
++++     nldir = await _platform
++++         .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
++++     if (nldir != null) {
+++++      state = 'secondif';
++++       await prefs.setString(
++++         'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
++++         nldir,
++++       );
++++     }
++++   }
++++-  if (nldir == null) return Directory('/non_existent');
+++++  if (nldir == null) return Directory('/non_existent/$state');
++++   return Directory(nldir);
++++ }
++++diff --git i/lib/service.dart w/lib/service.dart
++++index 948dac1..c52f674 100644
++++--- i/lib/service.dart
+++++++ w/lib/service.dart
++++@@ -302,7 +302,7 @@ Future<void> startP3p({
++++ Future<String> getBinPath() async {
++++   switch (getPlatform()) {
++++     case OS.android:
++++-      (await getAndroidNativeLibraryDirectory()).path;
+++++      return (await getAndroidNativeLibraryDirectory()).path;
++++ 
++++     case _:
++++       final prefs = await SharedPreferences.getInstance();
++++@@ -315,5 +315,4 @@ Future<String> getBinPath() async {
++++         _ => p.join((await getApplicationSupportDirectory()).path, 'bin'),
++++       };
++++   }
++++-  return '/non_existent';
++++ }
++++diff --git i/pubspec.lock w/pubspec.lock
++++index 37758b1..85e6f5e 100644
++++--- i/pubspec.lock
+++++++ w/pubspec.lock
++++@@ -565,6 +565,30 @@ packages:
++++       url: "https://pub.dev"
++++     source: hosted
++++     version: "3.7.3"
+++++  qr:
+++++    dependency: transitive
+++++    description:
+++++      name: qr
+++++      sha256: "64957a3930367bf97cc211a5af99551d630f2f4625e38af10edd6b19131b64b3"
+++++      url: "https://pub.dev"
+++++    source: hosted
+++++    version: "3.0.1"
+++++  qr_flutter:
+++++    dependency: "direct main"
+++++    description:
+++++      name: qr_flutter
+++++      sha256: "5095f0fc6e3f71d08adef8feccc8cea4f12eec18a2e31c2e8d82cb6019f4b097"
+++++      url: "https://pub.dev"
+++++    source: hosted
+++++    version: "4.1.0"
+++++  qrscan:
+++++    dependency: "direct main"
+++++    description:
+++++      name: qrscan
+++++      sha256: "0ee72eca0dcbc35ab74894010e3589c3675ddb7c5a551d5f29ab0d3bb1bfb135"
+++++      url: "https://pub.dev"
+++++    source: hosted
+++++    version: "0.3.3"
++++   quiver:
++++     dependency: transitive
++++     description:
++++diff --git i/pubspec.yaml w/pubspec.yaml
++++index c9c2ef9..46e3f44 100644
++++--- i/pubspec.yaml
+++++++ w/pubspec.yaml
++++@@ -31,6 +31,8 @@ dependencies:
++++   path: ^1.8.3
++++   path_provider: ^2.1.0
++++   permission_handler: ^10.4.3
+++++  qr_flutter: ^4.1.0
+++++  qrscan: ^0.3.3
++++   shared_preferences: ^2.2.0
++++   shelf: ^1.4.1
++++   sqlite3_flutter_libs: ^0.5.0
++++no changes added to commit (use "git add" and/or "git commit -a")
+++diff --git i/lib/main.dart w/lib/main.dart
+++index 43574e7..6dda900 100644
+++--- i/lib/main.dart
++++++ w/lib/main.dart
+++@@ -8,6 +8,7 @@ import 'package:p3p/p3p.dart';
+++ import 'package:p3pch4t/consts.dart';
+++ import 'package:p3pch4t/pages/home.dart';
+++ import 'package:p3pch4t/pages/landing.dart';
++++import 'package:p3pch4t/platform_interface.dart';
+++ import 'package:p3pch4t/service.dart';
+++ import 'package:permission_handler/permission_handler.dart';
+++ import 'package:shared_preferences/shared_preferences.dart';
+++@@ -17,6 +18,10 @@ P3p? p3p;
+++ 
+++ void main() async {
+++   WidgetsFlutterBinding.ensureInitialized();
++++  // we need to call it here because otherwise it may not store information
++++  // about path used in the SharedPreferences - that will lead to I2pdEnsure
++++  // (and possibly others) being unable to find the path.
++++  await getAndroidNativeLibraryDirectory(forceRefresh: true);
+++   final prefs = await SharedPreferences.getInstance();
+++   if (prefs.getString('priv_key') == null) {
+++     runApp(
+++diff --git i/lib/pages/adduser.dart w/lib/pages/adduser.dart
+++index 74b7e16..acdc18f 100644
+++--- i/lib/pages/adduser.dart
++++++ w/lib/pages/adduser.dart
+++@@ -1,9 +1,15 @@
+++ // ignore_for_file: public_member_api_docs
+++ 
++++import 'dart:async';
++++import 'dart:math';
++++
+++ import 'package:flutter/material.dart';
+++ import 'package:p3p/p3p.dart';
+++ import 'package:p3pch4t/helpers.dart';
+++ import 'package:p3pch4t/main.dart';
++++import 'package:permission_handler/permission_handler.dart';
++++import 'package:qr_flutter/qr_flutter.dart';
++++import 'package:qrscan/qrscan.dart' as scanner;
+++ 
+++ class AddUserPage extends StatefulWidget {
+++   const AddUserPage({super.key});
+++@@ -37,33 +43,101 @@ class _AddUserPageState extends State<AddUserPage> {
+++       body: SingleChildScrollView(
+++         child: Column(
+++           children: [
+++-            SelectableText('FP: ${selfUi!.publicKey.fingerprint}'),
+++-            SelectableText(
+++-              selfUi!.publicKey.publickey,
+++-              style: const TextStyle(fontSize: 7),
+++-            ),
++++            SelectableText(selfUi!.publicKey.fingerprint),
+++             TextField(
+++               controller: pkCtrl,
+++-              maxLines: 16,
+++-              minLines: 16,
++++              minLines: 1,
+++               decoration: const InputDecoration(
+++                 border: OutlineInputBorder(),
+++               ),
+++             ),
+++-            OutlinedButton(
+++-              onPressed: () async {
+++-                final ui = await UserInfo.create(p3p!, pkCtrl.text);
+++-                if (ui == null) {
+++-                  return;
+++-                }
+++-                if (!mounted) return;
+++-                Navigator.of(context).pop();
+++-              },
+++-              child: const Text('Add'),
++++            SizedBox(
++++              width: double.maxFinite,
++++              child: ElevatedButton(
++++                onPressed: () async {
++++                  final ui = await UserInfo.create(p3p!, pkCtrl.text);
++++                  if (ui == null) {
++++                    return;
++++                  }
++++                  if (!mounted) return;
++++                  Navigator.of(context).pop();
++++                },
++++                child: const Text('Add'),
++++              ),
++++            ),
++++            URQR(text: selfUi!.publicKey.publickey),
++++            const Text(
++++              'After scanning one part of qr, click the code to move to '
++++              'the next part',
++++            ),
++++            SizedBox(
++++              width: double.maxFinite,
++++              child: ElevatedButton.icon(
++++                onPressed: scan,
++++                icon: const Icon(Icons.camera),
++++                label: const Text('Scan'),
++++              ),
+++             ),
+++           ],
+++         ),
+++       ),
+++     );
+++   }
++++
++++  Future<void> scan() async {
++++    const total = 9999;
++++    await Permission.camera.request();
++++    while (true) {
++++      final cameraScanResult = await scanner.scan();
++++      if (cameraScanResult == null) break;
++++
++++      cameraScanResult.split('|');
++++    }
++++  }
++++}
++++
++++class URQR extends StatefulWidget {
++++  const URQR({required this.text, super.key});
++++
++++  final String text;
++++
++++  @override
++++  _URQRState createState() => _URQRState();
++++}
++++
++++class _URQRState extends State<URQR> {
++++  late List<String> texts;
++++  final int divider = 500;
++++  @override
++++  void initState() {
++++    final tmpList = <String>[];
++++    for (var i = 0; i < widget.text.length; i++) {
++++      if (i % divider == 0) {
++++        final tempString =
++++            widget.text.substring(i, min(i + divider, widget.text.length));
++++        tmpList.add(tempString);
++++      }
++++    }
++++    setState(() {
++++      texts = tmpList;
++++    });
++++
++++    super.initState();
++++  }
++++
++++  int i = 0;
++++  @override
++++  Widget build(BuildContext context) {
++++    return InkWell(
++++      onTap: () {
++++        setState(() {
++++          i = (i + 1) % texts.length;
++++        });
++++      },
++++      child: QrImageView(
++++        data: '$i/${texts.length}|${texts[i]}',
++++        backgroundColor: Colors.white,
++++      ),
++++    );
++++  }
+++ }
+++diff --git i/lib/pages/landing.dart w/lib/pages/landing.dart
+++index 90df48f..178b12e 100644
+++--- i/lib/pages/landing.dart
++++++ w/lib/pages/landing.dart
+++@@ -6,6 +6,7 @@ import 'package:dart_pg/dart_pg.dart';
+++ import 'package:flutter/material.dart';
+++ import 'package:p3pch4t/helpers.dart';
+++ import 'package:p3pch4t/pages/home.dart';
++++import 'package:p3pch4t/pages/register.dart';
+++ import 'package:p3pch4t/service.dart';
+++ import 'package:permission_handler/permission_handler.dart';
+++ import 'package:shared_preferences/shared_preferences.dart';
+++@@ -49,34 +50,11 @@ class _LandingPageState extends State<LandingPage> {
+++               const Spacer(),
+++               OutlinedButton(
+++                 onPressed: () async {
+++-                  setState(() {
+++-                    isLoading = true;
+++-                  });
+++-                  final prefs = await SharedPreferences.getInstance();
+++-
+++-                  debugPrint('generating privkey...');
+++-                  final privkey = await OpenPGP.generateKey(
+++-                    ['name <user@example.org>'],
+++-                    'no_passpharse',
+++-                  );
+++-                  await prefs.setString('priv_key', privkey.armor());
+++-                  setState(() {
+++-                    isLoading = false;
+++-                  });
+++-                  if (!mounted) {
+++-                    await Future<void>.delayed(const Duration(seconds: 1));
+++-                    exit(1);
+++-                  }
+++-                  if (Platform.isAndroid) {
+++-                    await Permission.notification.request();
+++-                  }
+++-                  await initializeService();
+++-                  if (mounted) return;
+++                   // it is used safely here.
+++                   // ignore: use_build_context_synchronously
+++                   await Navigator.of(context).pushReplacement(
+++                     MaterialPageRoute<void>(
+++-                      builder: (context) => const HomePage(),
++++                      builder: (context) => const RegisterPage(),
+++                     ),
+++                   );
+++                 },
+++diff --git i/lib/pages/settings.dart w/lib/pages/settings.dart
+++index deebc0f..c62f9dc 100644
+++--- i/lib/pages/settings.dart
++++++ w/lib/pages/settings.dart
+++@@ -1,5 +1,6 @@
+++ // ignore_for_file: public_member_api_docs
+++ 
++++import 'package:flutter/foundation.dart';
+++ import 'package:flutter/material.dart';
+++ import 'package:flutter_i2p/flutter_i2p.dart';
+++ import 'package:p3pch4t/main.dart';
+++diff --git i/lib/pages/webxdcfileview_android.dart w/lib/pages/webxdcfileview_android.dart
+++index e861d55..828cb46 100644
+++--- i/lib/pages/webxdcfileview_android.dart
++++++ w/lib/pages/webxdcfileview_android.dart
+++@@ -78,8 +78,12 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
+++         // I/flutter (14004):     "descr": "localuser scored 25 in Tower Builder!"
+++         // I/flutter (14004): }
+++         if (kDebugMode) print('p3p_native_sendUpdate:');
++++        // p0.message is what we receive from the browser
+++         final jBody = json.decode(p0.message) as Map<String, dynamic>;
++++        // what is interesting for us is the "update" field, as can be seen in
++++        // comment above.
+++         final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
++++        // 'info' field, according to WebXDC field should be sent to the room.
+++         if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
+++           await p3p!.sendMessage(
+++             widget.chatroom,
+++@@ -90,25 +94,33 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
+++         // append the update to update file.
+++         final updateElm = await getUpdateElement();
+++         if (updateElm == null) {
++++          // We don't have the .jsonp file - despite the fact that it was
++++          // created.
+++           if (mounted) Navigator.of(context).pop();
+++           return;
+++         }
+++ 
++++        // For whatever reason I'd love to use microseconds, because idk
++++        // but I can't because JS.
++++        final timestamp = DateTime.now().millisecondsSinceEpoch;
+++         await updateElm.file.writeAsString(
+++-          "\n${json.encode(jBodyUpdate["payload"])}",
++++          "\n$timestamp:${json.encode(jBodyUpdate["payload"])}",
+++           mode: FileMode.append,
+++           flush: true,
+++         );
+++-        final lines = await updateElm.file.readAsLines();
++++
+++         await updateElm.updateContent(
+++           p3p!,
+++         );
+++         final jsPayload = '''
+++ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
+++   window.webxdc.setUpdateListenerList[i]({
++++    // NOTE: Is it possible to exploit this somehow?
++++    // talking about the dart side of things.
++++    // I'm sorry for you if you had to dig here from JS world.
+++     "payload": ${json.encode(jBodyUpdate["payload"])},
+++-    "serial": ${lines.length},
+++-    "max_serial": ${lines.length},
++++    "serial": $timestamp,
++++    "max_serial": $timestamp,
+++     "info": null,
+++     "document": null,
+++     "summary": null,
+++@@ -141,16 +153,21 @@ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
+++           return;
+++         }
+++         final lines = updateElm.file.readAsLinesSync();
++++        final regexp = RegExp('/^[0-9]+:/gm');
+++         for (var i = 0; i < lines.length; i++) {
++++          final match = regexp.stringMatch(lines[i]);
++++          if (match == null) continue;
++++          final matchInt = match.replaceAll(':', '');
+++           try {
+++-            final payload = json.encode(json.decode(lines[i]));
++++            final payload =
++++                json.encode(json.decode(lines[i].substring(match.length)));
+++             final jsPayload = '''
+++ console.log("setUpdateListener: hook id: $i");
+++ 
+++ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+++   "payload": $payload,
+++-  "serial": $i,
+++-  "max_serial": ${lines.length},
++++  "serial": $matchInt,
++++  "max_serial": $matchInt,
+++   "info": null,
+++   "document": null,
+++   "summary": null,
+++@@ -210,7 +227,7 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+++     final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
+++     final wpath = widget.webxdcFile.path;
+++     final desiredPath = p.normalize(
+++-      (wpath.split('/')
++++      (wpath.split(Platform.isWindows ? r'\' : '/')
+++             ..removeLast()
+++             ..add('.${p.basename(wpath)}.update.jsonp'))
+++           .join('/'),
+++diff --git i/lib/platform_interface.dart w/lib/platform_interface.dart
+++index eeb2cba..32772f3 100644
+++--- i/lib/platform_interface.dart
++++++ w/lib/platform_interface.dart
+++@@ -9,20 +9,23 @@ const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');
+++ Future<Directory> getAndroidNativeLibraryDirectory({
+++   bool forceRefresh = false,
+++ }) async {
++++  var state = 'prefs';
+++   final prefs = await SharedPreferences.getInstance();
+++   var nldir =
+++       prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');
+++ 
+++   if (nldir == null || forceRefresh) {
++++    state = 'firstif';
+++     nldir = await _platform
+++         .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
+++     if (nldir != null) {
++++      state = 'secondif';
+++       await prefs.setString(
+++         'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
+++         nldir,
+++       );
+++     }
+++   }
+++-  if (nldir == null) return Directory('/non_existent');
++++  if (nldir == null) return Directory('/non_existent/$state');
+++   return Directory(nldir);
+++ }
+++diff --git i/lib/service.dart w/lib/service.dart
+++index 948dac1..c52f674 100644
+++--- i/lib/service.dart
++++++ w/lib/service.dart
+++@@ -302,7 +302,7 @@ Future<void> startP3p({
+++ Future<String> getBinPath() async {
+++   switch (getPlatform()) {
+++     case OS.android:
+++-      (await getAndroidNativeLibraryDirectory()).path;
++++      return (await getAndroidNativeLibraryDirectory()).path;
+++ 
+++     case _:
+++       final prefs = await SharedPreferences.getInstance();
+++@@ -315,5 +315,4 @@ Future<String> getBinPath() async {
+++         _ => p.join((await getApplicationSupportDirectory()).path, 'bin'),
+++       };
+++   }
+++-  return '/non_existent';
+++ }
+++diff --git i/pubspec.lock w/pubspec.lock
+++index 37758b1..85e6f5e 100644
+++--- i/pubspec.lock
++++++ w/pubspec.lock
+++@@ -565,6 +565,30 @@ packages:
+++       url: "https://pub.dev"
+++     source: hosted
+++     version: "3.7.3"
++++  qr:
++++    dependency: transitive
++++    description:
++++      name: qr
++++      sha256: "64957a3930367bf97cc211a5af99551d630f2f4625e38af10edd6b19131b64b3"
++++      url: "https://pub.dev"
++++    source: hosted
++++    version: "3.0.1"
++++  qr_flutter:
++++    dependency: "direct main"
++++    description:
++++      name: qr_flutter
++++      sha256: "5095f0fc6e3f71d08adef8feccc8cea4f12eec18a2e31c2e8d82cb6019f4b097"
++++      url: "https://pub.dev"
++++    source: hosted
++++    version: "4.1.0"
++++  qrscan:
++++    dependency: "direct main"
++++    description:
++++      name: qrscan
++++      sha256: "0ee72eca0dcbc35ab74894010e3589c3675ddb7c5a551d5f29ab0d3bb1bfb135"
++++      url: "https://pub.dev"
++++    source: hosted
++++    version: "0.3.3"
+++   quiver:
+++     dependency: transitive
+++     description:
+++diff --git i/pubspec.yaml w/pubspec.yaml
+++index c9c2ef9..46e3f44 100644
+++--- i/pubspec.yaml
++++++ w/pubspec.yaml
+++@@ -31,6 +31,8 @@ dependencies:
+++   path: ^1.8.3
+++   path_provider: ^2.1.0
+++   permission_handler: ^10.4.3
++++  qr_flutter: ^4.1.0
++++  qrscan: ^0.3.3
+++   shared_preferences: ^2.2.0
+++   shelf: ^1.4.1
+++   sqlite3_flutter_libs: ^0.5.0
+++no changes added to commit (use "git add" and/or "git commit -a")
++diff --git i/lib/main.dart w/lib/main.dart
++index 43574e7..6dda900 100644
++--- i/lib/main.dart
+++++ w/lib/main.dart
++@@ -8,6 +8,7 @@ import 'package:p3p/p3p.dart';
++ import 'package:p3pch4t/consts.dart';
++ import 'package:p3pch4t/pages/home.dart';
++ import 'package:p3pch4t/pages/landing.dart';
+++import 'package:p3pch4t/platform_interface.dart';
++ import 'package:p3pch4t/service.dart';
++ import 'package:permission_handler/permission_handler.dart';
++ import 'package:shared_preferences/shared_preferences.dart';
++@@ -17,6 +18,10 @@ P3p? p3p;
++ 
++ void main() async {
++   WidgetsFlutterBinding.ensureInitialized();
+++  // we need to call it here because otherwise it may not store information
+++  // about path used in the SharedPreferences - that will lead to I2pdEnsure
+++  // (and possibly others) being unable to find the path.
+++  await getAndroidNativeLibraryDirectory(forceRefresh: true);
++   final prefs = await SharedPreferences.getInstance();
++   if (prefs.getString('priv_key') == null) {
++     runApp(
++diff --git i/lib/pages/adduser.dart w/lib/pages/adduser.dart
++index 74b7e16..4ea94a4 100644
++--- i/lib/pages/adduser.dart
+++++ w/lib/pages/adduser.dart
++@@ -1,9 +1,15 @@
++ // ignore_for_file: public_member_api_docs
++ 
+++import 'dart:async';
+++import 'dart:math';
+++
++ import 'package:flutter/material.dart';
++ import 'package:p3p/p3p.dart';
++ import 'package:p3pch4t/helpers.dart';
++ import 'package:p3pch4t/main.dart';
+++import 'package:permission_handler/permission_handler.dart';
+++import 'package:qr_flutter/qr_flutter.dart';
+++import 'package:qrscan/qrscan.dart' as scanner;
++ 
++ class AddUserPage extends StatefulWidget {
++   const AddUserPage({super.key});
++@@ -37,33 +43,124 @@ class _AddUserPageState extends State<AddUserPage> {
++       body: SingleChildScrollView(
++         child: Column(
++           children: [
++-            SelectableText('FP: ${selfUi!.publicKey.fingerprint}'),
++-            SelectableText(
++-              selfUi!.publicKey.publickey,
++-              style: const TextStyle(fontSize: 7),
++-            ),
+++            SelectableText(selfUi!.publicKey.fingerprint),
++             TextField(
++               controller: pkCtrl,
++-              maxLines: 16,
++-              minLines: 16,
+++              minLines: 1,
+++              maxLines: 12,
++               decoration: const InputDecoration(
++                 border: OutlineInputBorder(),
++               ),
++             ),
++-            OutlinedButton(
++-              onPressed: () async {
++-                final ui = await UserInfo.create(p3p!, pkCtrl.text);
++-                if (ui == null) {
++-                  return;
++-                }
++-                if (!mounted) return;
++-                Navigator.of(context).pop();
++-              },
++-              child: const Text('Add'),
+++            SizedBox(
+++              width: double.maxFinite,
+++              child: ElevatedButton(
+++                onPressed: () async {
+++                  final ui = await UserInfo.create(p3p!, pkCtrl.text);
+++                  if (ui == null) {
+++                    return;
+++                  }
+++                  if (!mounted) return;
+++                  Navigator.of(context).pop();
+++                },
+++                child: const Text('Add'),
+++              ),
+++            ),
+++            URQR(text: selfUi!.publicKey.publickey),
+++            const Text(
+++              'After scanning one part of qr, click the code to move to '
+++              'the next part',
+++            ),
+++            SizedBox(
+++              width: double.maxFinite,
+++              child: ElevatedButton.icon(
+++                onPressed: scan,
+++                icon: const Icon(Icons.camera),
+++                label: const Text('Scan'),
+++              ),
+++            ),
+++            const Divider(),
+++            SelectableText(
+++              selfUi!.publicKey.publickey,
+++              style: const TextStyle(
+++                fontFamily: 'monospace',
+++                fontSize: 7,
+++              ),
++             ),
++           ],
++         ),
++       ),
++     );
++   }
+++
+++  Future<void> scan() async {
+++    var total = 9999;
+++    final parts = List.generate(total, (index) => '');
+++    await Permission.camera.request();
+++    while (true) {
+++      final cameraScanResult = await scanner.scan();
+++      if (cameraScanResult == null) break;
+++
+++      final list = cameraScanResult.split('|');
+++      final meta = list[0].split('/');
+++      total = int.parse(meta[1]);
+++      parts[int.parse(meta[0])] = list[1];
+++      setState(() {
+++        pkCtrl.text = parts.join();
+++      });
+++      var done = true;
+++      for (var i = 0; i < total; i++) {
+++        if (parts[i] == '') done = false;
+++      }
+++      if (done) {
+++        break;
+++      }
+++    }
+++  }
+++}
+++
+++class URQR extends StatefulWidget {
+++  const URQR({required this.text, super.key});
+++
+++  final String text;
+++
+++  @override
+++  _URQRState createState() => _URQRState();
+++}
+++
+++class _URQRState extends State<URQR> {
+++  late List<String> texts;
+++  final int divider = 500;
+++  @override
+++  void initState() {
+++    final tmpList = <String>[];
+++    for (var i = 0; i < widget.text.length; i++) {
+++      if (i % divider == 0) {
+++        final tempString =
+++            widget.text.substring(i, min(i + divider, widget.text.length));
+++        tmpList.add(tempString);
+++      }
+++    }
+++    setState(() {
+++      texts = tmpList;
+++    });
+++
+++    super.initState();
+++  }
+++
+++  int i = 0;
+++  @override
+++  Widget build(BuildContext context) {
+++    return InkWell(
+++      onTap: () {
+++        setState(() {
+++          i = (i + 1) % texts.length;
+++        });
+++      },
+++      child: QrImageView(
+++        data: '$i/${texts.length}|${texts[i]}',
+++        backgroundColor: Colors.white,
+++      ),
+++    );
+++  }
++ }
++diff --git i/lib/pages/landing.dart w/lib/pages/landing.dart
++index 90df48f..178b12e 100644
++--- i/lib/pages/landing.dart
+++++ w/lib/pages/landing.dart
++@@ -6,6 +6,7 @@ import 'package:dart_pg/dart_pg.dart';
++ import 'package:flutter/material.dart';
++ import 'package:p3pch4t/helpers.dart';
++ import 'package:p3pch4t/pages/home.dart';
+++import 'package:p3pch4t/pages/register.dart';
++ import 'package:p3pch4t/service.dart';
++ import 'package:permission_handler/permission_handler.dart';
++ import 'package:shared_preferences/shared_preferences.dart';
++@@ -49,34 +50,11 @@ class _LandingPageState extends State<LandingPage> {
++               const Spacer(),
++               OutlinedButton(
++                 onPressed: () async {
++-                  setState(() {
++-                    isLoading = true;
++-                  });
++-                  final prefs = await SharedPreferences.getInstance();
++-
++-                  debugPrint('generating privkey...');
++-                  final privkey = await OpenPGP.generateKey(
++-                    ['name <user@example.org>'],
++-                    'no_passpharse',
++-                  );
++-                  await prefs.setString('priv_key', privkey.armor());
++-                  setState(() {
++-                    isLoading = false;
++-                  });
++-                  if (!mounted) {
++-                    await Future<void>.delayed(const Duration(seconds: 1));
++-                    exit(1);
++-                  }
++-                  if (Platform.isAndroid) {
++-                    await Permission.notification.request();
++-                  }
++-                  await initializeService();
++-                  if (mounted) return;
++                   // it is used safely here.
++                   // ignore: use_build_context_synchronously
++                   await Navigator.of(context).pushReplacement(
++                     MaterialPageRoute<void>(
++-                      builder: (context) => const HomePage(),
+++                      builder: (context) => const RegisterPage(),
++                     ),
++                   );
++                 },
++diff --git i/lib/pages/settings.dart w/lib/pages/settings.dart
++index deebc0f..c62f9dc 100644
++--- i/lib/pages/settings.dart
+++++ w/lib/pages/settings.dart
++@@ -1,5 +1,6 @@
++ // ignore_for_file: public_member_api_docs
++ 
+++import 'package:flutter/foundation.dart';
++ import 'package:flutter/material.dart';
++ import 'package:flutter_i2p/flutter_i2p.dart';
++ import 'package:p3pch4t/main.dart';
++diff --git i/lib/pages/webxdcfileview_android.dart w/lib/pages/webxdcfileview_android.dart
++index e861d55..828cb46 100644
++--- i/lib/pages/webxdcfileview_android.dart
+++++ w/lib/pages/webxdcfileview_android.dart
++@@ -78,8 +78,12 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
++         // I/flutter (14004):     "descr": "localuser scored 25 in Tower Builder!"
++         // I/flutter (14004): }
++         if (kDebugMode) print('p3p_native_sendUpdate:');
+++        // p0.message is what we receive from the browser
++         final jBody = json.decode(p0.message) as Map<String, dynamic>;
+++        // what is interesting for us is the "update" field, as can be seen in
+++        // comment above.
++         final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
+++        // 'info' field, according to WebXDC field should be sent to the room.
++         if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
++           await p3p!.sendMessage(
++             widget.chatroom,
++@@ -90,25 +94,33 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
++         // append the update to update file.
++         final updateElm = await getUpdateElement();
++         if (updateElm == null) {
+++          // We don't have the .jsonp file - despite the fact that it was
+++          // created.
++           if (mounted) Navigator.of(context).pop();
++           return;
++         }
++ 
+++        // For whatever reason I'd love to use microseconds, because idk
+++        // but I can't because JS.
+++        final timestamp = DateTime.now().millisecondsSinceEpoch;
++         await updateElm.file.writeAsString(
++-          "\n${json.encode(jBodyUpdate["payload"])}",
+++          "\n$timestamp:${json.encode(jBodyUpdate["payload"])}",
++           mode: FileMode.append,
++           flush: true,
++         );
++-        final lines = await updateElm.file.readAsLines();
+++
++         await updateElm.updateContent(
++           p3p!,
++         );
++         final jsPayload = '''
++ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
++   window.webxdc.setUpdateListenerList[i]({
+++    // NOTE: Is it possible to exploit this somehow?
+++    // talking about the dart side of things.
+++    // I'm sorry for you if you had to dig here from JS world.
++     "payload": ${json.encode(jBodyUpdate["payload"])},
++-    "serial": ${lines.length},
++-    "max_serial": ${lines.length},
+++    "serial": $timestamp,
+++    "max_serial": $timestamp,
++     "info": null,
++     "document": null,
++     "summary": null,
++@@ -141,16 +153,21 @@ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
++           return;
++         }
++         final lines = updateElm.file.readAsLinesSync();
+++        final regexp = RegExp('/^[0-9]+:/gm');
++         for (var i = 0; i < lines.length; i++) {
+++          final match = regexp.stringMatch(lines[i]);
+++          if (match == null) continue;
+++          final matchInt = match.replaceAll(':', '');
++           try {
++-            final payload = json.encode(json.decode(lines[i]));
+++            final payload =
+++                json.encode(json.decode(lines[i].substring(match.length)));
++             final jsPayload = '''
++ console.log("setUpdateListener: hook id: $i");
++ 
++ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
++   "payload": $payload,
++-  "serial": $i,
++-  "max_serial": ${lines.length},
+++  "serial": $matchInt,
+++  "max_serial": $matchInt,
++   "info": null,
++   "document": null,
++   "summary": null,
++@@ -210,7 +227,7 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
++     final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
++     final wpath = widget.webxdcFile.path;
++     final desiredPath = p.normalize(
++-      (wpath.split('/')
+++      (wpath.split(Platform.isWindows ? r'\' : '/')
++             ..removeLast()
++             ..add('.${p.basename(wpath)}.update.jsonp'))
++           .join('/'),
++diff --git i/lib/platform_interface.dart w/lib/platform_interface.dart
++index eeb2cba..32772f3 100644
++--- i/lib/platform_interface.dart
+++++ w/lib/platform_interface.dart
++@@ -9,20 +9,23 @@ const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');
++ Future<Directory> getAndroidNativeLibraryDirectory({
++   bool forceRefresh = false,
++ }) async {
+++  var state = 'prefs';
++   final prefs = await SharedPreferences.getInstance();
++   var nldir =
++       prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');
++ 
++   if (nldir == null || forceRefresh) {
+++    state = 'firstif';
++     nldir = await _platform
++         .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
++     if (nldir != null) {
+++      state = 'secondif';
++       await prefs.setString(
++         'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
++         nldir,
++       );
++     }
++   }
++-  if (nldir == null) return Directory('/non_existent');
+++  if (nldir == null) return Directory('/non_existent/$state');
++   return Directory(nldir);
++ }
++diff --git i/lib/service.dart w/lib/service.dart
++index 948dac1..c52f674 100644
++--- i/lib/service.dart
+++++ w/lib/service.dart
++@@ -302,7 +302,7 @@ Future<void> startP3p({
++ Future<String> getBinPath() async {
++   switch (getPlatform()) {
++     case OS.android:
++-      (await getAndroidNativeLibraryDirectory()).path;
+++      return (await getAndroidNativeLibraryDirectory()).path;
++ 
++     case _:
++       final prefs = await SharedPreferences.getInstance();
++@@ -315,5 +315,4 @@ Future<String> getBinPath() async {
++         _ => p.join((await getApplicationSupportDirectory()).path, 'bin'),
++       };
++   }
++-  return '/non_existent';
++ }
++diff --git i/pubspec.lock w/pubspec.lock
++index 37758b1..85e6f5e 100644
++--- i/pubspec.lock
+++++ w/pubspec.lock
++@@ -565,6 +565,30 @@ packages:
++       url: "https://pub.dev"
++     source: hosted
++     version: "3.7.3"
+++  qr:
+++    dependency: transitive
+++    description:
+++      name: qr
+++      sha256: "64957a3930367bf97cc211a5af99551d630f2f4625e38af10edd6b19131b64b3"
+++      url: "https://pub.dev"
+++    source: hosted
+++    version: "3.0.1"
+++  qr_flutter:
+++    dependency: "direct main"
+++    description:
+++      name: qr_flutter
+++      sha256: "5095f0fc6e3f71d08adef8feccc8cea4f12eec18a2e31c2e8d82cb6019f4b097"
+++      url: "https://pub.dev"
+++    source: hosted
+++    version: "4.1.0"
+++  qrscan:
+++    dependency: "direct main"
+++    description:
+++      name: qrscan
+++      sha256: "0ee72eca0dcbc35ab74894010e3589c3675ddb7c5a551d5f29ab0d3bb1bfb135"
+++      url: "https://pub.dev"
+++    source: hosted
+++    version: "0.3.3"
++   quiver:
++     dependency: transitive
++     description:
++diff --git i/pubspec.yaml w/pubspec.yaml
++index c9c2ef9..46e3f44 100644
++--- i/pubspec.yaml
+++++ w/pubspec.yaml
++@@ -31,6 +31,8 @@ dependencies:
++   path: ^1.8.3
++   path_provider: ^2.1.0
++   permission_handler: ^10.4.3
+++  qr_flutter: ^4.1.0
+++  qrscan: ^0.3.3
++   shared_preferences: ^2.2.0
++   shelf: ^1.4.1
++   sqlite3_flutter_libs: ^0.5.0
++no changes added to commit (use "git add" and/or "git commit -a")
+diff --git i/lib/main.dart w/lib/main.dart
+index 43574e7..6dda900 100644
+--- i/lib/main.dart
++++ w/lib/main.dart
+@@ -8,6 +8,7 @@ import 'package:p3p/p3p.dart';
+ import 'package:p3pch4t/consts.dart';
+ import 'package:p3pch4t/pages/home.dart';
+ import 'package:p3pch4t/pages/landing.dart';
++import 'package:p3pch4t/platform_interface.dart';
+ import 'package:p3pch4t/service.dart';
+ import 'package:permission_handler/permission_handler.dart';
+ import 'package:shared_preferences/shared_preferences.dart';
+@@ -17,6 +18,10 @@ P3p? p3p;
+ 
+ void main() async {
+   WidgetsFlutterBinding.ensureInitialized();
++  // we need to call it here because otherwise it may not store information
++  // about path used in the SharedPreferences - that will lead to I2pdEnsure
++  // (and possibly others) being unable to find the path.
++  await getAndroidNativeLibraryDirectory(forceRefresh: true);
+   final prefs = await SharedPreferences.getInstance();
+   if (prefs.getString('priv_key') == null) {
+     runApp(
+diff --git i/lib/pages/adduser.dart w/lib/pages/adduser.dart
+index 74b7e16..4ea94a4 100644
+--- i/lib/pages/adduser.dart
++++ w/lib/pages/adduser.dart
+@@ -1,9 +1,15 @@
+ // ignore_for_file: public_member_api_docs
+ 
++import 'dart:async';
++import 'dart:math';
++
+ import 'package:flutter/material.dart';
+ import 'package:p3p/p3p.dart';
+ import 'package:p3pch4t/helpers.dart';
+ import 'package:p3pch4t/main.dart';
++import 'package:permission_handler/permission_handler.dart';
++import 'package:qr_flutter/qr_flutter.dart';
++import 'package:qrscan/qrscan.dart' as scanner;
+ 
+ class AddUserPage extends StatefulWidget {
+   const AddUserPage({super.key});
+@@ -37,33 +43,124 @@ class _AddUserPageState extends State<AddUserPage> {
+       body: SingleChildScrollView(
+         child: Column(
+           children: [
+-            SelectableText('FP: ${selfUi!.publicKey.fingerprint}'),
+-            SelectableText(
+-              selfUi!.publicKey.publickey,
+-              style: const TextStyle(fontSize: 7),
+-            ),
++            SelectableText(selfUi!.publicKey.fingerprint),
+             TextField(
+               controller: pkCtrl,
+-              maxLines: 16,
+-              minLines: 16,
++              minLines: 1,
++              maxLines: 12,
+               decoration: const InputDecoration(
+                 border: OutlineInputBorder(),
+               ),
+             ),
+-            OutlinedButton(
+-              onPressed: () async {
+-                final ui = await UserInfo.create(p3p!, pkCtrl.text);
+-                if (ui == null) {
+-                  return;
+-                }
+-                if (!mounted) return;
+-                Navigator.of(context).pop();
+-              },
+-              child: const Text('Add'),
++            SizedBox(
++              width: double.maxFinite,
++              child: ElevatedButton(
++                onPressed: () async {
++                  final ui = await UserInfo.create(p3p!, pkCtrl.text);
++                  if (ui == null) {
++                    return;
++                  }
++                  if (!mounted) return;
++                  Navigator.of(context).pop();
++                },
++                child: const Text('Add'),
++              ),
++            ),
++            URQR(text: selfUi!.publicKey.publickey),
++            const Text(
++              'After scanning one part of qr, click the code to move to '
++              'the next part',
++            ),
++            SizedBox(
++              width: double.maxFinite,
++              child: ElevatedButton.icon(
++                onPressed: scan,
++                icon: const Icon(Icons.camera),
++                label: const Text('Scan'),
++              ),
++            ),
++            const Divider(),
++            SelectableText(
++              selfUi!.publicKey.publickey,
++              style: const TextStyle(
++                fontFamily: 'monospace',
++                fontSize: 7,
++              ),
+             ),
+           ],
+         ),
+       ),
+     );
+   }
++
++  Future<void> scan() async {
++    var total = 9999;
++    final parts = List.generate(total, (index) => '');
++    await Permission.camera.request();
++    while (true) {
++      final cameraScanResult = await scanner.scan();
++      if (cameraScanResult == null) break;
++
++      final list = cameraScanResult.split('|');
++      final meta = list[0].split('/');
++      total = int.parse(meta[1]);
++      parts[int.parse(meta[0])] = list[1];
++      setState(() {
++        pkCtrl.text = parts.join();
++      });
++      var done = true;
++      for (var i = 0; i < total; i++) {
++        if (parts[i] == '') done = false;
++      }
++      if (done) {
++        break;
++      }
++    }
++  }
++}
++
++class URQR extends StatefulWidget {
++  const URQR({required this.text, super.key});
++
++  final String text;
++
++  @override
++  _URQRState createState() => _URQRState();
++}
++
++class _URQRState extends State<URQR> {
++  late List<String> texts;
++  final int divider = 500;
++  @override
++  void initState() {
++    final tmpList = <String>[];
++    for (var i = 0; i < widget.text.length; i++) {
++      if (i % divider == 0) {
++        final tempString =
++            widget.text.substring(i, min(i + divider, widget.text.length));
++        tmpList.add(tempString);
++      }
++    }
++    setState(() {
++      texts = tmpList;
++    });
++
++    super.initState();
++  }
++
++  int i = 0;
++  @override
++  Widget build(BuildContext context) {
++    return InkWell(
++      onTap: () {
++        setState(() {
++          i = (i + 1) % texts.length;
++        });
++      },
++      child: QrImageView(
++        data: '$i/${texts.length}|${texts[i]}',
++        backgroundColor: Colors.white,
++      ),
++    );
++  }
+ }
+diff --git i/lib/pages/fileview.dart w/lib/pages/fileview.dart
+index e32b179..f625f62 100644
+--- i/lib/pages/fileview.dart
++++ w/lib/pages/fileview.dart
+@@ -38,9 +38,9 @@ class _FileViewState extends State<FileView> {
+           children: [
+             if (file.downloadedSizeBytes != file.sizeBytes)
+               LinearProgressIndicator(
+-                value: file.downloadedSizeBytes == 0
++                value: file.downloadedSizeBytes == 0 || file.sizeBytes == 0
+                     ? null
+-                    : file.downloadedSizeBytes / file.sizeBytes,
++                    : file.downloadedSizeBytes / file.sizeBytes + 1,
+               ),
+             SelectableText(const JsonEncoder.withIndent('   ').convert(file)),
+             TextField(
+diff --git i/lib/pages/landing.dart w/lib/pages/landing.dart
+index 90df48f..178b12e 100644
+--- i/lib/pages/landing.dart
++++ w/lib/pages/landing.dart
+@@ -6,6 +6,7 @@ import 'package:dart_pg/dart_pg.dart';
+ import 'package:flutter/material.dart';
+ import 'package:p3pch4t/helpers.dart';
+ import 'package:p3pch4t/pages/home.dart';
++import 'package:p3pch4t/pages/register.dart';
+ import 'package:p3pch4t/service.dart';
+ import 'package:permission_handler/permission_handler.dart';
+ import 'package:shared_preferences/shared_preferences.dart';
+@@ -49,34 +50,11 @@ class _LandingPageState extends State<LandingPage> {
+               const Spacer(),
+               OutlinedButton(
+                 onPressed: () async {
+-                  setState(() {
+-                    isLoading = true;
+-                  });
+-                  final prefs = await SharedPreferences.getInstance();
+-
+-                  debugPrint('generating privkey...');
+-                  final privkey = await OpenPGP.generateKey(
+-                    ['name <user@example.org>'],
+-                    'no_passpharse',
+-                  );
+-                  await prefs.setString('priv_key', privkey.armor());
+-                  setState(() {
+-                    isLoading = false;
+-                  });
+-                  if (!mounted) {
+-                    await Future<void>.delayed(const Duration(seconds: 1));
+-                    exit(1);
+-                  }
+-                  if (Platform.isAndroid) {
+-                    await Permission.notification.request();
+-                  }
+-                  await initializeService();
+-                  if (mounted) return;
+                   // it is used safely here.
+                   // ignore: use_build_context_synchronously
+                   await Navigator.of(context).pushReplacement(
+                     MaterialPageRoute<void>(
+-                      builder: (context) => const HomePage(),
++                      builder: (context) => const RegisterPage(),
+                     ),
+                   );
+                 },
+diff --git i/lib/pages/settings.dart w/lib/pages/settings.dart
+index deebc0f..c62f9dc 100644
+--- i/lib/pages/settings.dart
++++ w/lib/pages/settings.dart
+@@ -1,5 +1,6 @@
+ // ignore_for_file: public_member_api_docs
+ 
++import 'package:flutter/foundation.dart';
+ import 'package:flutter/material.dart';
+ import 'package:flutter_i2p/flutter_i2p.dart';
+ import 'package:p3pch4t/main.dart';
+diff --git i/lib/pages/webxdcfileview_android.dart w/lib/pages/webxdcfileview_android.dart
+index e861d55..52478de 100644
+--- i/lib/pages/webxdcfileview_android.dart
++++ w/lib/pages/webxdcfileview_android.dart
+@@ -78,8 +78,12 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
+         // I/flutter (14004):     "descr": "localuser scored 25 in Tower Builder!"
+         // I/flutter (14004): }
+         if (kDebugMode) print('p3p_native_sendUpdate:');
++        // p0.message is what we receive from the browser
+         final jBody = json.decode(p0.message) as Map<String, dynamic>;
++        // what is interesting for us is the "update" field, as can be seen in
++        // comment above.
+         final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
++        // 'info' field, according to WebXDC field should be sent to the room.
+         if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
+           await p3p!.sendMessage(
+             widget.chatroom,
+@@ -90,25 +94,33 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
+         // append the update to update file.
+         final updateElm = await getUpdateElement();
+         if (updateElm == null) {
++          // We don't have the .jsonp file - despite the fact that it was
++          // created.
+           if (mounted) Navigator.of(context).pop();
+           return;
+         }
+ 
++        // For whatever reason I'd love to use microseconds, because idk
++        // but I can't because JS.
++        final timestamp = DateTime.now().millisecondsSinceEpoch;
+         await updateElm.file.writeAsString(
+-          "\n${json.encode(jBodyUpdate["payload"])}",
++          "\n$timestamp:${json.encode(jBodyUpdate["payload"])}",
+           mode: FileMode.append,
+           flush: true,
+         );
+-        final lines = await updateElm.file.readAsLines();
++
+         await updateElm.updateContent(
+           p3p!,
+         );
+         final jsPayload = '''
+ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
+   window.webxdc.setUpdateListenerList[i]({
++    // NOTE: Is it possible to exploit this somehow?
++    // talking about the dart side of things.
++    // I'm sorry for you if you had to dig here from JS world.
+     "payload": ${json.encode(jBodyUpdate["payload"])},
+-    "serial": ${lines.length},
+-    "max_serial": ${lines.length},
++    "serial": $timestamp,
++    "max_serial": $timestamp,
+     "info": null,
+     "document": null,
+     "summary": null,
+@@ -140,17 +152,29 @@ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
+           if (mounted) Navigator.of(context).pop();
+           return;
+         }
++        if (!updateElm.file.existsSync()) {
++          updateElm.file.createSync(recursive: true);
++        }
++        if (updateElm.file.lengthSync() == 0) {
++          return;
++        }
++        p3p?.print('updateElm.file.length: ${updateElm.file.lengthSync()}');
+         final lines = updateElm.file.readAsLinesSync();
++        final regexp = RegExp('/^[0-9]+:/gm');
+         for (var i = 0; i < lines.length; i++) {
++          final match = regexp.stringMatch(lines[i]);
++          if (match == null) continue;
++          final matchInt = match.replaceAll(':', '');
+           try {
+-            final payload = json.encode(json.decode(lines[i]));
++            final payload =
++                json.encode(json.decode(lines[i].substring(match.length)));
+             final jsPayload = '''
+ console.log("setUpdateListener: hook id: $i");
+ 
+ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+   "payload": $payload,
+-  "serial": $i,
+-  "max_serial": ${lines.length},
++  "serial": $matchInt,
++  "max_serial": $matchInt,
+   "info": null,
+   "document": null,
+   "summary": null,
+@@ -210,7 +234,7 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+     final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
+     final wpath = widget.webxdcFile.path;
+     final desiredPath = p.normalize(
+-      (wpath.split('/')
++      (wpath.split(Platform.isWindows ? r'\' : '/')
+             ..removeLast()
+             ..add('.${p.basename(wpath)}.update.jsonp'))
+           .join('/'),
+@@ -221,6 +245,8 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+         updateElm = felm;
+       }
+     }
++    print(desiredPath);
++    print(updateElm?.path);
+     if (updateElm == null) {
+       updateElm = await widget.chatroom.fileStore.putFileStoreElement(
+         p3p!,
+@@ -232,7 +258,8 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
+       )
+         ..shouldFetch = true;
+       await updateElm.updateContent(p3p!);
+-
++      print(desiredPath);
++      print(updateElm.path);
+       return updateElm;
+     }
+     return updateElm;
+diff --git i/lib/platform_interface.dart w/lib/platform_interface.dart
+index eeb2cba..32772f3 100644
+--- i/lib/platform_interface.dart
++++ w/lib/platform_interface.dart
+@@ -9,20 +9,23 @@ const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');
+ Future<Directory> getAndroidNativeLibraryDirectory({
+   bool forceRefresh = false,
+ }) async {
++  var state = 'prefs';
+   final prefs = await SharedPreferences.getInstance();
+   var nldir =
+       prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');
+ 
+   if (nldir == null || forceRefresh) {
++    state = 'firstif';
+     nldir = await _platform
+         .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
+     if (nldir != null) {
++      state = 'secondif';
+       await prefs.setString(
+         'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
+         nldir,
+       );
+     }
+   }
+-  if (nldir == null) return Directory('/non_existent');
++  if (nldir == null) return Directory('/non_existent/$state');
+   return Directory(nldir);
+ }
+diff --git i/lib/service.dart w/lib/service.dart
+index 948dac1..84d69cf 100644
+--- i/lib/service.dart
++++ w/lib/service.dart
+@@ -274,10 +274,11 @@ Future<void> startP3p({
+     filestore,
+     prefs.getString('priv_key')!,
+     prefs.getString('priv_passpharse') ?? 'no_passpharse',
+-    db.DatabaseImplDrift(
+-      dbFolder: p.join(filestore, 'dbdrift'),
+-      singularFileStore: false,
+-    ),
++    await DatabaseImplIsar.open(dbPath: p.join(filestore, 'dbisar')),
++    // db.DatabaseImplDrift(
++    //   dbFolder: p.join(filestore, 'dbdrift'),
++    //   singularFileStore: false,
++    // ),
+     scheduleTasks: scheduleTasks,
+     listen: listen,
+     reachableI2p: eepsite == null
+@@ -302,7 +303,7 @@ Future<void> startP3p({
+ Future<String> getBinPath() async {
+   switch (getPlatform()) {
+     case OS.android:
+-      (await getAndroidNativeLibraryDirectory()).path;
++      return (await getAndroidNativeLibraryDirectory()).path;
+ 
+     case _:
+       final prefs = await SharedPreferences.getInstance();
+@@ -315,5 +316,4 @@ Future<String> getBinPath() async {
+         _ => p.join((await getApplicationSupportDirectory()).path, 'bin'),
+       };
+   }
+-  return '/non_existent';
+ }
+diff --git i/linux/flutter/generated_plugin_registrant.cc w/linux/flutter/generated_plugin_registrant.cc
+index 4c0025f..6f1c30e 100644
+--- i/linux/flutter/generated_plugin_registrant.cc
++++ w/linux/flutter/generated_plugin_registrant.cc
+@@ -6,10 +6,14 @@
+ 
+ #include "generated_plugin_registrant.h"
+ 
++#include <isar_flutter_libs/isar_flutter_libs_plugin.h>
+ #include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>
+ #include <url_launcher_linux/url_launcher_plugin.h>
+ 
+ void fl_register_plugins(FlPluginRegistry* registry) {
++  g_autoptr(FlPluginRegistrar) isar_flutter_libs_registrar =
++      fl_plugin_registry_get_registrar_for_plugin(registry, "IsarFlutterLibsPlugin");
++  isar_flutter_libs_plugin_register_with_registrar(isar_flutter_libs_registrar);
+   g_autoptr(FlPluginRegistrar) sqlite3_flutter_libs_registrar =
+       fl_plugin_registry_get_registrar_for_plugin(registry, "Sqlite3FlutterLibsPlugin");
+   sqlite3_flutter_libs_plugin_register_with_registrar(sqlite3_flutter_libs_registrar);
+diff --git i/linux/flutter/generated_plugins.cmake w/linux/flutter/generated_plugins.cmake
+index c8d24e7..4b42f86 100644
+--- i/linux/flutter/generated_plugins.cmake
++++ w/linux/flutter/generated_plugins.cmake
+@@ -3,6 +3,7 @@
+ #
+ 
+ list(APPEND FLUTTER_PLUGIN_LIST
++  isar_flutter_libs
+   sqlite3_flutter_libs
+   url_launcher_linux
+ )
+diff --git i/macos/Flutter/GeneratedPluginRegistrant.swift w/macos/Flutter/GeneratedPluginRegistrant.swift
+index 353781e..5f53011 100644
+--- i/macos/Flutter/GeneratedPluginRegistrant.swift
++++ w/macos/Flutter/GeneratedPluginRegistrant.swift
+@@ -6,6 +6,7 @@ import FlutterMacOS
+ import Foundation
+ 
+ import flutter_local_notifications
++import isar_flutter_libs
+ import path_provider_foundation
+ import shared_preferences_foundation
+ import sqlite3_flutter_libs
+@@ -13,6 +14,7 @@ import url_launcher_macos
+ 
+ func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
+   FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin"))
++  IsarFlutterLibsPlugin.register(with: registry.registrar(forPlugin: "IsarFlutterLibsPlugin"))
+   PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
+   SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
+   Sqlite3FlutterLibsPlugin.register(with: registry.registrar(forPlugin: "Sqlite3FlutterLibsPlugin"))
+diff --git i/pubspec.lock w/pubspec.lock
+index 37758b1..92863c8 100644
+--- i/pubspec.lock
++++ w/pubspec.lock
+@@ -176,14 +176,6 @@ packages:
+       url: "https://pub.dev"
+     source: hosted
+     version: "1.1.0"
+-  flat_buffers:
+-    dependency: transitive
+-    description:
+-      name: flat_buffers
+-      sha256: "23e2ced0d8e8ecdffbd9f267f49a668c74438393b9acaeac1c724123e3764263"
+-      url: "https://pub.dev"
+-    source: hosted
+-    version: "2.0.5"
+   flutter:
+     dependency: "direct main"
+     description: flutter
+@@ -326,6 +318,22 @@ packages:
+       url: "https://pub.dev"
+     source: hosted
+     version: "4.0.2"
++  isar:
++    dependency: transitive
++    description:
++      name: isar
++      sha256: "99165dadb2cf2329d3140198363a7e7bff9bbd441871898a87e26914d25cf1ea"
++      url: "https://pub.dev"
++    source: hosted
++    version: "3.1.0+1"
++  isar_flutter_libs:
++    dependency: "direct main"
++    description:
++      name: isar_flutter_libs
++      sha256: bc6768cc4b9c61aabff77152e7f33b4b17d2fc93134f7af1c3dd51500fe8d5e8
++      url: "https://pub.dev"
++    source: hosted
++    version: "3.1.0+1"
+   js:
+     dependency: transitive
+     description:
+@@ -398,14 +406,6 @@ packages:
+       url: "https://pub.dev"
+     source: hosted
+     version: "3.0.1"
+-  objectbox:
+-    dependency: transitive
+-    description:
+-      name: objectbox
+-      sha256: f5687c7bd2ec5e97f07dbe06bcdcff46094f5d6e52a1c01c722e1a410434ac1e
+-      url: "https://pub.dev"
+-    source: hosted
+-    version: "2.3.0"
+   open_file:
+     dependency: "direct main"
+     description:
+@@ -565,6 +565,30 @@ packages:
+       url: "https://pub.dev"
+     source: hosted
+     version: "3.7.3"
++  qr:
++    dependency: transitive
++    description:
++      name: qr
++      sha256: "64957a3930367bf97cc211a5af99551d630f2f4625e38af10edd6b19131b64b3"
++      url: "https://pub.dev"
++    source: hosted
++    version: "3.0.1"
++  qr_flutter:
++    dependency: "direct main"
++    description:
++      name: qr_flutter
++      sha256: "5095f0fc6e3f71d08adef8feccc8cea4f12eec18a2e31c2e8d82cb6019f4b097"
++      url: "https://pub.dev"
++    source: hosted
++    version: "4.1.0"
++  qrscan:
++    dependency: "direct main"
++    description:
++      name: qrscan
++      sha256: "0ee72eca0dcbc35ab74894010e3589c3675ddb7c5a551d5f29ab0d3bb1bfb135"
++      url: "https://pub.dev"
++    source: hosted
++    version: "0.3.3"
+   quiver:
+     dependency: transitive
+     description:
+diff --git i/pubspec.yaml w/pubspec.yaml
+index c9c2ef9..2e26916 100644
+--- i/pubspec.yaml
++++ w/pubspec.yaml
+@@ -23,6 +23,7 @@ dependencies:
+   flutter_local_notifications: ^15.1.0+1
+   flutter_markdown: ^0.6.17+1
+   http: ^1.1.0
++  isar_flutter_libs: ^3.1.0+1
+   markdown: ^7.1.1
+   mime: ^1.0.4
+   open_file: ^3.3.2
+@@ -31,6 +32,8 @@ dependencies:
+   path: ^1.8.3
+   path_provider: ^2.1.0
+   permission_handler: ^10.4.3
++  qr_flutter: ^4.1.0
++  qrscan: ^0.3.3
+   shared_preferences: ^2.2.0
+   shelf: ^1.4.1
+   sqlite3_flutter_libs: ^0.5.0
+diff --git i/windows/flutter/generated_plugin_registrant.cc w/windows/flutter/generated_plugin_registrant.cc
+index 36f7ed9..85cbd69 100644
+--- i/windows/flutter/generated_plugin_registrant.cc
++++ w/windows/flutter/generated_plugin_registrant.cc
+@@ -6,11 +6,14 @@
+ 
+ #include "generated_plugin_registrant.h"
+ 
++#include <isar_flutter_libs/isar_flutter_libs_plugin.h>
+ #include <permission_handler_windows/permission_handler_windows_plugin.h>
+ #include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>
+ #include <url_launcher_windows/url_launcher_windows.h>
+ 
+ void RegisterPlugins(flutter::PluginRegistry* registry) {
++  IsarFlutterLibsPluginRegisterWithRegistrar(
++      registry->GetRegistrarForPlugin("IsarFlutterLibsPlugin"));
+   PermissionHandlerWindowsPluginRegisterWithRegistrar(
+       registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
+   Sqlite3FlutterLibsPluginRegisterWithRegistrar(
+diff --git i/windows/flutter/generated_plugins.cmake w/windows/flutter/generated_plugins.cmake
+index f8c387f..c320052 100644
+--- i/windows/flutter/generated_plugins.cmake
++++ w/windows/flutter/generated_plugins.cmake
+@@ -3,6 +3,7 @@
+ #
+ 
+ list(APPEND FLUTTER_PLUGIN_LIST
++  isar_flutter_libs
+   permission_handler_windows
+   sqlite3_flutter_libs
+   url_launcher_windows
+no changes added to commit (use "git add" and/or "git commit -a")
diff --git i/lib/main.dart w/lib/main.dart
index 43574e7..6dda900 100644
--- i/lib/main.dart
+++ w/lib/main.dart
@@ -8,6 +8,7 @@ import 'package:p3p/p3p.dart';
 import 'package:p3pch4t/consts.dart';
 import 'package:p3pch4t/pages/home.dart';
 import 'package:p3pch4t/pages/landing.dart';
+import 'package:p3pch4t/platform_interface.dart';
 import 'package:p3pch4t/service.dart';
 import 'package:permission_handler/permission_handler.dart';
 import 'package:shared_preferences/shared_preferences.dart';
@@ -17,6 +18,10 @@ P3p? p3p;
 
 void main() async {
   WidgetsFlutterBinding.ensureInitialized();
+  // we need to call it here because otherwise it may not store information
+  // about path used in the SharedPreferences - that will lead to I2pdEnsure
+  // (and possibly others) being unable to find the path.
+  await getAndroidNativeLibraryDirectory(forceRefresh: true);
   final prefs = await SharedPreferences.getInstance();
   if (prefs.getString('priv_key') == null) {
     runApp(
diff --git i/lib/pages/adduser.dart w/lib/pages/adduser.dart
index 74b7e16..4ea94a4 100644
--- i/lib/pages/adduser.dart
+++ w/lib/pages/adduser.dart
@@ -1,9 +1,15 @@
 // ignore_for_file: public_member_api_docs
 
+import 'dart:async';
+import 'dart:math';
+
 import 'package:flutter/material.dart';
 import 'package:p3p/p3p.dart';
 import 'package:p3pch4t/helpers.dart';
 import 'package:p3pch4t/main.dart';
+import 'package:permission_handler/permission_handler.dart';
+import 'package:qr_flutter/qr_flutter.dart';
+import 'package:qrscan/qrscan.dart' as scanner;
 
 class AddUserPage extends StatefulWidget {
   const AddUserPage({super.key});
@@ -37,33 +43,124 @@ class _AddUserPageState extends State<AddUserPage> {
       body: SingleChildScrollView(
         child: Column(
           children: [
-            SelectableText('FP: ${selfUi!.publicKey.fingerprint}'),
-            SelectableText(
-              selfUi!.publicKey.publickey,
-              style: const TextStyle(fontSize: 7),
-            ),
+            SelectableText(selfUi!.publicKey.fingerprint),
             TextField(
               controller: pkCtrl,
-              maxLines: 16,
-              minLines: 16,
+              minLines: 1,
+              maxLines: 12,
               decoration: const InputDecoration(
                 border: OutlineInputBorder(),
               ),
             ),
-            OutlinedButton(
-              onPressed: () async {
-                final ui = await UserInfo.create(p3p!, pkCtrl.text);
-                if (ui == null) {
-                  return;
-                }
-                if (!mounted) return;
-                Navigator.of(context).pop();
-              },
-              child: const Text('Add'),
+            SizedBox(
+              width: double.maxFinite,
+              child: ElevatedButton(
+                onPressed: () async {
+                  final ui = await UserInfo.create(p3p!, pkCtrl.text);
+                  if (ui == null) {
+                    return;
+                  }
+                  if (!mounted) return;
+                  Navigator.of(context).pop();
+                },
+                child: const Text('Add'),
+              ),
+            ),
+            URQR(text: selfUi!.publicKey.publickey),
+            const Text(
+              'After scanning one part of qr, click the code to move to '
+              'the next part',
+            ),
+            SizedBox(
+              width: double.maxFinite,
+              child: ElevatedButton.icon(
+                onPressed: scan,
+                icon: const Icon(Icons.camera),
+                label: const Text('Scan'),
+              ),
+            ),
+            const Divider(),
+            SelectableText(
+              selfUi!.publicKey.publickey,
+              style: const TextStyle(
+                fontFamily: 'monospace',
+                fontSize: 7,
+              ),
             ),
           ],
         ),
       ),
     );
   }
+
+  Future<void> scan() async {
+    var total = 9999;
+    final parts = List.generate(total, (index) => '');
+    await Permission.camera.request();
+    while (true) {
+      final cameraScanResult = await scanner.scan();
+      if (cameraScanResult == null) break;
+
+      final list = cameraScanResult.split('|');
+      final meta = list[0].split('/');
+      total = int.parse(meta[1]);
+      parts[int.parse(meta[0])] = list[1];
+      setState(() {
+        pkCtrl.text = parts.join();
+      });
+      var done = true;
+      for (var i = 0; i < total; i++) {
+        if (parts[i] == '') done = false;
+      }
+      if (done) {
+        break;
+      }
+    }
+  }
+}
+
+class URQR extends StatefulWidget {
+  const URQR({required this.text, super.key});
+
+  final String text;
+
+  @override
+  _URQRState createState() => _URQRState();
+}
+
+class _URQRState extends State<URQR> {
+  late List<String> texts;
+  final int divider = 500;
+  @override
+  void initState() {
+    final tmpList = <String>[];
+    for (var i = 0; i < widget.text.length; i++) {
+      if (i % divider == 0) {
+        final tempString =
+            widget.text.substring(i, min(i + divider, widget.text.length));
+        tmpList.add(tempString);
+      }
+    }
+    setState(() {
+      texts = tmpList;
+    });
+
+    super.initState();
+  }
+
+  int i = 0;
+  @override
+  Widget build(BuildContext context) {
+    return InkWell(
+      onTap: () {
+        setState(() {
+          i = (i + 1) % texts.length;
+        });
+      },
+      child: QrImageView(
+        data: '$i/${texts.length}|${texts[i]}',
+        backgroundColor: Colors.white,
+      ),
+    );
+  }
 }
diff --git i/lib/pages/fileview.dart w/lib/pages/fileview.dart
index e32b179..f625f62 100644
--- i/lib/pages/fileview.dart
+++ w/lib/pages/fileview.dart
@@ -38,9 +38,9 @@ class _FileViewState extends State<FileView> {
           children: [
             if (file.downloadedSizeBytes != file.sizeBytes)
               LinearProgressIndicator(
-                value: file.downloadedSizeBytes == 0
+                value: file.downloadedSizeBytes == 0 || file.sizeBytes == 0
                     ? null
-                    : file.downloadedSizeBytes / file.sizeBytes,
+                    : file.downloadedSizeBytes / file.sizeBytes + 1,
               ),
             SelectableText(const JsonEncoder.withIndent('   ').convert(file)),
             TextField(
diff --git i/lib/pages/landing.dart w/lib/pages/landing.dart
index 90df48f..178b12e 100644
--- i/lib/pages/landing.dart
+++ w/lib/pages/landing.dart
@@ -6,6 +6,7 @@ import 'package:dart_pg/dart_pg.dart';
 import 'package:flutter/material.dart';
 import 'package:p3pch4t/helpers.dart';
 import 'package:p3pch4t/pages/home.dart';
+import 'package:p3pch4t/pages/register.dart';
 import 'package:p3pch4t/service.dart';
 import 'package:permission_handler/permission_handler.dart';
 import 'package:shared_preferences/shared_preferences.dart';
@@ -49,34 +50,11 @@ class _LandingPageState extends State<LandingPage> {
               const Spacer(),
               OutlinedButton(
                 onPressed: () async {
-                  setState(() {
-                    isLoading = true;
-                  });
-                  final prefs = await SharedPreferences.getInstance();
-
-                  debugPrint('generating privkey...');
-                  final privkey = await OpenPGP.generateKey(
-                    ['name <user@example.org>'],
-                    'no_passpharse',
-                  );
-                  await prefs.setString('priv_key', privkey.armor());
-                  setState(() {
-                    isLoading = false;
-                  });
-                  if (!mounted) {
-                    await Future<void>.delayed(const Duration(seconds: 1));
-                    exit(1);
-                  }
-                  if (Platform.isAndroid) {
-                    await Permission.notification.request();
-                  }
-                  await initializeService();
-                  if (mounted) return;
                   // it is used safely here.
                   // ignore: use_build_context_synchronously
                   await Navigator.of(context).pushReplacement(
                     MaterialPageRoute<void>(
-                      builder: (context) => const HomePage(),
+                      builder: (context) => const RegisterPage(),
                     ),
                   );
                 },
diff --git i/lib/pages/settings.dart w/lib/pages/settings.dart
index deebc0f..885136f 100644
--- i/lib/pages/settings.dart
+++ w/lib/pages/settings.dart
@@ -1,5 +1,6 @@
 // ignore_for_file: public_member_api_docs
 
+import 'package:flutter/foundation.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_i2p/flutter_i2p.dart';
 import 'package:p3pch4t/main.dart';
@@ -59,11 +60,11 @@ class _SettingsPageState extends State<SettingsPage> {
                 onPressed: () async {
                   final si = await p3p!.getSelfInfo();
                   si.name = nameCtrl.text;
-                  await p3p!.db.save(si);
-                  await p3p!.db.getAllUserInfo().then((value) {
+                  si.id = await p3p!.db.save(si);
+                  await p3p!.db.getAllUserInfo().then((value) async {
                     for (final element in value) {
                       element.lastIntroduce = DateTime(1998);
-                      p3p!.db.save(element);
+                      element.id = await p3p!.db.save(element);
                     }
                   });
                   if (!mounted) return;
diff --git i/lib/pages/webxdcfileview_android.dart w/lib/pages/webxdcfileview_android.dart
index e861d55..52478de 100644
--- i/lib/pages/webxdcfileview_android.dart
+++ w/lib/pages/webxdcfileview_android.dart
@@ -78,8 +78,12 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
         // I/flutter (14004):     "descr": "localuser scored 25 in Tower Builder!"
         // I/flutter (14004): }
         if (kDebugMode) print('p3p_native_sendUpdate:');
+        // p0.message is what we receive from the browser
         final jBody = json.decode(p0.message) as Map<String, dynamic>;
+        // what is interesting for us is the "update" field, as can be seen in
+        // comment above.
         final jBodyUpdate = jBody['update'] as Map<String, dynamic>;
+        // 'info' field, according to WebXDC field should be sent to the room.
         if (jBodyUpdate['info'] != null && jBodyUpdate['info'] != '') {
           await p3p!.sendMessage(
             widget.chatroom,
@@ -90,25 +94,33 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
         // append the update to update file.
         final updateElm = await getUpdateElement();
         if (updateElm == null) {
+          // We don't have the .jsonp file - despite the fact that it was
+          // created.
           if (mounted) Navigator.of(context).pop();
           return;
         }
 
+        // For whatever reason I'd love to use microseconds, because idk
+        // but I can't because JS.
+        final timestamp = DateTime.now().millisecondsSinceEpoch;
         await updateElm.file.writeAsString(
-          "\n${json.encode(jBodyUpdate["payload"])}",
+          "\n$timestamp:${json.encode(jBodyUpdate["payload"])}",
           mode: FileMode.append,
           flush: true,
         );
-        final lines = await updateElm.file.readAsLines();
+
         await updateElm.updateContent(
           p3p!,
         );
         final jsPayload = '''
 for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
   window.webxdc.setUpdateListenerList[i]({
+    // NOTE: Is it possible to exploit this somehow?
+    // talking about the dart side of things.
+    // I'm sorry for you if you had to dig here from JS world.
     "payload": ${json.encode(jBodyUpdate["payload"])},
-    "serial": ${lines.length},
-    "max_serial": ${lines.length},
+    "serial": $timestamp,
+    "max_serial": $timestamp,
     "info": null,
     "document": null,
     "summary": null,
@@ -140,17 +152,29 @@ for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
           if (mounted) Navigator.of(context).pop();
           return;
         }
+        if (!updateElm.file.existsSync()) {
+          updateElm.file.createSync(recursive: true);
+        }
+        if (updateElm.file.lengthSync() == 0) {
+          return;
+        }
+        p3p?.print('updateElm.file.length: ${updateElm.file.lengthSync()}');
         final lines = updateElm.file.readAsLinesSync();
+        final regexp = RegExp('/^[0-9]+:/gm');
         for (var i = 0; i < lines.length; i++) {
+          final match = regexp.stringMatch(lines[i]);
+          if (match == null) continue;
+          final matchInt = match.replaceAll(':', '');
           try {
-            final payload = json.encode(json.decode(lines[i]));
+            final payload =
+                json.encode(json.decode(lines[i].substring(match.length)));
             final jsPayload = '''
 console.log("setUpdateListener: hook id: $i");
 
 window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
   "payload": $payload,
-  "serial": $i,
-  "max_serial": ${lines.length},
+  "serial": $matchInt,
+  "max_serial": $matchInt,
   "info": null,
   "document": null,
   "summary": null,
@@ -210,7 +234,7 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
     final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
     final wpath = widget.webxdcFile.path;
     final desiredPath = p.normalize(
-      (wpath.split('/')
+      (wpath.split(Platform.isWindows ? r'\' : '/')
             ..removeLast()
             ..add('.${p.basename(wpath)}.update.jsonp'))
           .join('/'),
@@ -221,6 +245,8 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
         updateElm = felm;
       }
     }
+    print(desiredPath);
+    print(updateElm?.path);
     if (updateElm == null) {
       updateElm = await widget.chatroom.fileStore.putFileStoreElement(
         p3p!,
@@ -232,7 +258,8 @@ window.webxdc.setUpdateListenerList[${(jBody["listId"] as int) - 1}]({
       )
         ..shouldFetch = true;
       await updateElm.updateContent(p3p!);
-
+      print(desiredPath);
+      print(updateElm.path);
       return updateElm;
     }
     return updateElm;
diff --git i/lib/platform_interface.dart w/lib/platform_interface.dart
index eeb2cba..32772f3 100644
--- i/lib/platform_interface.dart
+++ w/lib/platform_interface.dart
@@ -9,20 +9,23 @@ const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');
 Future<Directory> getAndroidNativeLibraryDirectory({
   bool forceRefresh = false,
 }) async {
+  var state = 'prefs';
   final prefs = await SharedPreferences.getInstance();
   var nldir =
       prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');
 
   if (nldir == null || forceRefresh) {
+    state = 'firstif';
     nldir = await _platform
         .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
     if (nldir != null) {
+      state = 'secondif';
       await prefs.setString(
         'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
         nldir,
       );
     }
   }
-  if (nldir == null) return Directory('/non_existent');
+  if (nldir == null) return Directory('/non_existent/$state');
   return Directory(nldir);
 }
diff --git i/lib/service.dart w/lib/service.dart
index 948dac1..c5124ce 100644
--- i/lib/service.dart
+++ w/lib/service.dart
@@ -2,6 +2,7 @@
 
 import 'dart:async';
 import 'dart:io';
+import 'dart:ui';
 
 import 'package:dart_i2p/dart_i2p.dart';
 import 'package:flutter/foundation.dart';
@@ -85,8 +86,8 @@ Future<void> initializeService() async {
 }
 
 Future<void> onStart(ServiceInstance service) async {
-  WidgetsFlutterBinding.ensureInitialized();
-  // DartPluginRegistrant.ensureInitialized();
+  // WidgetsFlutterBinding.ensureInitialized();
+  DartPluginRegistrant.ensureInitialized();
   if (p3p == null) {
     if (kDebugMode) {
       print("NOTE: it looks like p3pch4t is not loaded, let's start it");
@@ -274,10 +275,11 @@ Future<void> startP3p({
     filestore,
     prefs.getString('priv_key')!,
     prefs.getString('priv_passpharse') ?? 'no_passpharse',
-    db.DatabaseImplDrift(
-      dbFolder: p.join(filestore, 'dbdrift'),
-      singularFileStore: false,
-    ),
+    await DatabaseImplIsar.open(dbPath: p.join(filestore, 'dbisar')),
+    // db.DatabaseImplDrift(
+    //   dbFolder: p.join(filestore, 'dbdrift'),
+    //   singularFileStore: false,
+    // ),
     scheduleTasks: scheduleTasks,
     listen: listen,
     reachableI2p: eepsite == null
@@ -302,7 +304,7 @@ Future<void> startP3p({
 Future<String> getBinPath() async {
   switch (getPlatform()) {
     case OS.android:
-      (await getAndroidNativeLibraryDirectory()).path;
+      return (await getAndroidNativeLibraryDirectory()).path;
 
     case _:
       final prefs = await SharedPreferences.getInstance();
@@ -315,5 +317,4 @@ Future<String> getBinPath() async {
         _ => p.join((await getApplicationSupportDirectory()).path, 'bin'),
       };
   }
-  return '/non_existent';
 }
diff --git i/linux/flutter/generated_plugin_registrant.cc w/linux/flutter/generated_plugin_registrant.cc
index 4c0025f..6f1c30e 100644
--- i/linux/flutter/generated_plugin_registrant.cc
+++ w/linux/flutter/generated_plugin_registrant.cc
@@ -6,10 +6,14 @@
 
 #include "generated_plugin_registrant.h"
 
+#include <isar_flutter_libs/isar_flutter_libs_plugin.h>
 #include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>
 #include <url_launcher_linux/url_launcher_plugin.h>
 
 void fl_register_plugins(FlPluginRegistry* registry) {
+  g_autoptr(FlPluginRegistrar) isar_flutter_libs_registrar =
+      fl_plugin_registry_get_registrar_for_plugin(registry, "IsarFlutterLibsPlugin");
+  isar_flutter_libs_plugin_register_with_registrar(isar_flutter_libs_registrar);
   g_autoptr(FlPluginRegistrar) sqlite3_flutter_libs_registrar =
       fl_plugin_registry_get_registrar_for_plugin(registry, "Sqlite3FlutterLibsPlugin");
   sqlite3_flutter_libs_plugin_register_with_registrar(sqlite3_flutter_libs_registrar);
diff --git i/linux/flutter/generated_plugins.cmake w/linux/flutter/generated_plugins.cmake
index c8d24e7..4b42f86 100644
--- i/linux/flutter/generated_plugins.cmake
+++ w/linux/flutter/generated_plugins.cmake
@@ -3,6 +3,7 @@
 #
 
 list(APPEND FLUTTER_PLUGIN_LIST
+  isar_flutter_libs
   sqlite3_flutter_libs
   url_launcher_linux
 )
diff --git i/macos/Flutter/GeneratedPluginRegistrant.swift w/macos/Flutter/GeneratedPluginRegistrant.swift
index 353781e..5f53011 100644
--- i/macos/Flutter/GeneratedPluginRegistrant.swift
+++ w/macos/Flutter/GeneratedPluginRegistrant.swift
@@ -6,6 +6,7 @@ import FlutterMacOS
 import Foundation
 
 import flutter_local_notifications
+import isar_flutter_libs
 import path_provider_foundation
 import shared_preferences_foundation
 import sqlite3_flutter_libs
@@ -13,6 +14,7 @@ import url_launcher_macos
 
 func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
   FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin"))
+  IsarFlutterLibsPlugin.register(with: registry.registrar(forPlugin: "IsarFlutterLibsPlugin"))
   PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
   SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
   Sqlite3FlutterLibsPlugin.register(with: registry.registrar(forPlugin: "Sqlite3FlutterLibsPlugin"))
diff --git i/pubspec.lock w/pubspec.lock
index 37758b1..92863c8 100644
--- i/pubspec.lock
+++ w/pubspec.lock
@@ -176,14 +176,6 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "1.1.0"
-  flat_buffers:
-    dependency: transitive
-    description:
-      name: flat_buffers
-      sha256: "23e2ced0d8e8ecdffbd9f267f49a668c74438393b9acaeac1c724123e3764263"
-      url: "https://pub.dev"
-    source: hosted
-    version: "2.0.5"
   flutter:
     dependency: "direct main"
     description: flutter
@@ -326,6 +318,22 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "4.0.2"
+  isar:
+    dependency: transitive
+    description:
+      name: isar
+      sha256: "99165dadb2cf2329d3140198363a7e7bff9bbd441871898a87e26914d25cf1ea"
+      url: "https://pub.dev"
+    source: hosted
+    version: "3.1.0+1"
+  isar_flutter_libs:
+    dependency: "direct main"
+    description:
+      name: isar_flutter_libs
+      sha256: bc6768cc4b9c61aabff77152e7f33b4b17d2fc93134f7af1c3dd51500fe8d5e8
+      url: "https://pub.dev"
+    source: hosted
+    version: "3.1.0+1"
   js:
     dependency: transitive
     description:
@@ -398,14 +406,6 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "3.0.1"
-  objectbox:
-    dependency: transitive
-    description:
-      name: objectbox
-      sha256: f5687c7bd2ec5e97f07dbe06bcdcff46094f5d6e52a1c01c722e1a410434ac1e
-      url: "https://pub.dev"
-    source: hosted
-    version: "2.3.0"
   open_file:
     dependency: "direct main"
     description:
@@ -565,6 +565,30 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "3.7.3"
+  qr:
+    dependency: transitive
+    description:
+      name: qr
+      sha256: "64957a3930367bf97cc211a5af99551d630f2f4625e38af10edd6b19131b64b3"
+      url: "https://pub.dev"
+    source: hosted
+    version: "3.0.1"
+  qr_flutter:
+    dependency: "direct main"
+    description:
+      name: qr_flutter
+      sha256: "5095f0fc6e3f71d08adef8feccc8cea4f12eec18a2e31c2e8d82cb6019f4b097"
+      url: "https://pub.dev"
+    source: hosted
+    version: "4.1.0"
+  qrscan:
+    dependency: "direct main"
+    description:
+      name: qrscan
+      sha256: "0ee72eca0dcbc35ab74894010e3589c3675ddb7c5a551d5f29ab0d3bb1bfb135"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.3.3"
   quiver:
     dependency: transitive
     description:
diff --git i/pubspec.yaml w/pubspec.yaml
index c9c2ef9..2e26916 100644
--- i/pubspec.yaml
+++ w/pubspec.yaml
@@ -23,6 +23,7 @@ dependencies:
   flutter_local_notifications: ^15.1.0+1
   flutter_markdown: ^0.6.17+1
   http: ^1.1.0
+  isar_flutter_libs: ^3.1.0+1
   markdown: ^7.1.1
   mime: ^1.0.4
   open_file: ^3.3.2
@@ -31,6 +32,8 @@ dependencies:
   path: ^1.8.3
   path_provider: ^2.1.0
   permission_handler: ^10.4.3
+  qr_flutter: ^4.1.0
+  qrscan: ^0.3.3
   shared_preferences: ^2.2.0
   shelf: ^1.4.1
   sqlite3_flutter_libs: ^0.5.0
diff --git i/windows/flutter/generated_plugin_registrant.cc w/windows/flutter/generated_plugin_registrant.cc
index 36f7ed9..85cbd69 100644
--- i/windows/flutter/generated_plugin_registrant.cc
+++ w/windows/flutter/generated_plugin_registrant.cc
@@ -6,11 +6,14 @@
 
 #include "generated_plugin_registrant.h"
 
+#include <isar_flutter_libs/isar_flutter_libs_plugin.h>
 #include <permission_handler_windows/permission_handler_windows_plugin.h>
 #include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>
 #include <url_launcher_windows/url_launcher_windows.h>
 
 void RegisterPlugins(flutter::PluginRegistry* registry) {
+  IsarFlutterLibsPluginRegisterWithRegistrar(
+      registry->GetRegistrarForPlugin("IsarFlutterLibsPlugin"));
   PermissionHandlerWindowsPluginRegisterWithRegistrar(
       registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
   Sqlite3FlutterLibsPluginRegisterWithRegistrar(
diff --git i/windows/flutter/generated_plugins.cmake w/windows/flutter/generated_plugins.cmake
index f8c387f..c320052 100644
--- i/windows/flutter/generated_plugins.cmake
+++ w/windows/flutter/generated_plugins.cmake
@@ -3,6 +3,7 @@
 #
 
 list(APPEND FLUTTER_PLUGIN_LIST
+  isar_flutter_libs
   permission_handler_windows
   sqlite3_flutter_libs
   url_launcher_windows
no changes added to commit (use "git add" and/or "git commit -a")
