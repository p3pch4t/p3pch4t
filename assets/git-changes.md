If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.


$ p3p.dart 

--------

On branch master
Your branch is up to date with 'origin/master'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   example/echobot/main.dart
	modified:   example/ssmdc.v1/main.dart
	modified:   lib/src/event.dart
	modified:   lib/src/filestore.dart
	modified:   lib/src/p3p_base.dart
	modified:   lib/src/reachable/local.dart
	modified:   lib/src/reachable/relay.dart
	modified:   lib/src/userinfo.dart
	modified:   lib/src/userinfossmdc.dart

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	lib/src/background.dart

--------------------------------------------------
Changes not staged for commit:
diff --git i/example/echobot/main.dart w/example/echobot/main.dart
index 0416aab..fa1fb4f 100644
--- i/example/echobot/main.dart
+++ w/example/echobot/main.dart
@@ -34,12 +34,8 @@ void main() async {
   // start processing new messages
 }
 
-void _messageCallback(P3p p3p, Message msg) {
-  final sender = msg.getSender(p3p);
-  p3p.sendMessage(
-    sender,
-    "I've received your message: ${msg.text}",
-  );
+void _messageCallback(P3p p3p, Message msg, UserInfo user) {
+  p3p.sendMessage(user, "I've received your message: ${msg.text}");
 }
 
 Future<void> generatePrivkey(File storedPgp) async {
diff --git i/example/ssmdc.v1/main.dart w/example/ssmdc.v1/main.dart
index 9ecd845..c465235 100644
--- i/example/ssmdc.v1/main.dart
+++ w/example/ssmdc.v1/main.dart
@@ -34,12 +34,8 @@ void main() async {
   // start processing new messages
 }
 
-void _messageCallback(P3p p3p, Message msg) {
-  final sender = msg.getSender(p3p);
-  p3p.sendMessage(
-    sender,
-    "I've received your message: ${msg.text}",
-  );
+void _messageCallback(P3p p3p, Message msg, UserInfo ui) {
+  p3p.sendMessage(ui, "I've received your message: ${msg.text}");
 }
 
 Future<void> generatePrivkey(File storedPgp) async {
diff --git i/lib/src/event.dart w/lib/src/event.dart
index d1646bd..aee229e 100644
--- i/lib/src/event.dart
+++ w/lib/src/event.dart
@@ -114,7 +114,7 @@ class Event {
         if (ui == null) {
           tryProcess(p3p, payload);
         } else {
-          await element.process(ui, p3p);
+          element.process(ui, p3p);
         }
       }
     }
@@ -172,28 +172,32 @@ class Event {
     return ret;
   }
 
-  Future<bool> process(UserInfo userInfo, P3p p3p) async {
-    print("processing.. - ${userInfo.id} - ${userInfo.name} - $eventType");
-    // JsonEncoder.withIndent('    ')
-    //     .convert(toJson())
-    //     .split("\n")
-    //     .forEach((element) {
-    //   print(element); // I hate the fact that flutter cuts the logs.
-    // });
+  void process(UserInfo userInfo, P3p p3p) async {
+    print("processing: - ${userInfo.id} - ${userInfo.name} - $eventType");
+
+    if (await p3p.callOnEvent(this)) {
+      if (id != 0) {
+        p3p.eventBox.remove(id);
+      }
+      return;
+    }
+
     switch (eventType) {
       case EventType.introduce:
-        return await processIntroduce(p3p);
+        processIntroduce(p3p);
       case EventType.introduceRequest:
-        return await processIntroduceRequest(p3p);
+        processIntroduceRequest(p3p);
       case EventType.message:
-        return await processMessage(p3p, userInfo);
+        processMessage(p3p, userInfo);
       case EventType.fileRequest:
-        return await processFileRequest(p3p, userInfo);
+        processFileRequest(p3p, userInfo);
       case EventType.file:
-        return await processFile(p3p, userInfo);
+        processFile(p3p, userInfo);
       case EventType.unimplemented || null:
         print("event: unimplemented");
-        return false;
+    }
+    if (id != 0) {
+      p3p.eventBox.remove(id);
     }
   }
 
@@ -250,12 +254,14 @@ class Event {
         }
       }
       if (!fileExisted) {
-        await useri.fileStore.putFileStoreElement(p3p,
-            localFile: null,
-            localFileSha512sum: elm["sha512sum"],
-            sizeBytes: elm["sizeBytes"],
-            fileInChatPath: elm["path"],
-            uuid: elm["uuid"]);
+        await useri.fileStore.putFileStoreElement(
+          p3p,
+          localFile: null,
+          localFileSha512sum: elm["sha512sum"],
+          sizeBytes: elm["sizeBytes"],
+          fileInChatPath: elm["path"],
+          uuid: elm["uuid"],
+        );
       }
     }
 
diff --git i/lib/src/filestore.dart w/lib/src/filestore.dart
index 7636814..5e68549 100644
--- i/lib/src/filestore.dart
+++ w/lib/src/filestore.dart
@@ -70,7 +70,15 @@ class FileStoreElement {
         useri.save(p3p);
       }
     }
+    if (p.basename(path).endsWith('xdc') ||
+        p.basename(path).endsWith('.jsonp')) {
+      shouldFetch = true;
+    }
     p3p.fileStoreElementBox.put(this);
+    p3p.callOnFileStoreElement(
+      FileStore(roomFingerprint: roomFingerprint),
+      this,
+    );
   }
 
   Future<void> updateContent(
@@ -108,7 +116,9 @@ class FileStore {
 
   Future<List<FileStoreElement>> getFileStoreElement(P3p p3p) async {
     return p3p.fileStoreElementBox
-        .query(FileStoreElement_.roomFingerprint.equals(roomFingerprint))
+        .query(FileStoreElement_.roomFingerprint
+            .equals(roomFingerprint)
+            .and(FileStoreElement_.isDeleted.equals(false)))
         .build()
         .find();
   }
diff --git i/lib/src/p3p_base.dart w/lib/src/p3p_base.dart
index a2ed1c4..2f82d66 100644
--- i/lib/src/p3p_base.dart
+++ w/lib/src/p3p_base.dart
@@ -1,23 +1,24 @@
 import 'dart:async';
-import 'dart:convert';
 import 'dart:io';
 
 import 'package:p3p/objectbox.g.dart';
+import 'package:p3p/src/background.dart';
 import 'package:p3p/src/chat.dart';
 import 'package:p3p/src/endpoint.dart';
 import 'package:p3p/src/error.dart';
 import 'package:p3p/src/event.dart';
 import 'package:p3p/src/filestore.dart';
 import 'package:p3p/src/publickey.dart';
+import 'package:p3p/src/reachable/local.dart';
 import 'package:p3p/src/reachable/relay.dart';
 import 'package:p3p/src/userinfo.dart';
 import 'package:dart_pg/dart_pg.dart' as pgp;
 import 'package:p3p/src/userinfossmdc.dart';
-import 'package:shelf/shelf.dart';
 import 'package:shelf/shelf_io.dart' as io;
-import 'package:shelf_router/shelf_router.dart';
 import 'package:path/path.dart' as p;
 
+bool storeIsOpen = false;
+
 class P3p {
   P3p({
     required this.privateKey,
@@ -43,21 +44,28 @@ class P3p {
     String privateKeyPassword,
   ) async {
     print("p3p: using $storePath");
+    final dbPath = Directory(p.join(storePath, 'dbv2'));
+    if (!await dbPath.exists()) await dbPath.create(recursive: true);
 
     final privkey = await (await pgp.OpenPGP.readPrivateKey(privateKey))
         .decrypt(privateKeyPassword);
-
-    final dbPath = Directory(p.join(storePath, 'dbv2'));
-    if (!await dbPath.exists()) await dbPath.create(recursive: true);
+    if (storeIsOpen == false) {
+      storeIsOpen = Store.isOpen(dbPath.absolute.path);
+    }
+    final newStore = storeIsOpen
+        ? Store.attach(getObjectBoxModel(), dbPath.absolute.path)
+        : openStore(
+            directory: dbPath.absolute.path,
+          );
     final p3p = P3p(
       privateKey: privkey,
       fileStorePath: p.join(storePath, 'files'),
-      store: openStore(
-        directory: dbPath.absolute.path,
-      ),
+      store: newStore,
     );
-    await p3p.listen();
-    p3p.scheduleTasks();
+    if (!storeIsOpen) {
+      await p3p.listen();
+      p3p._scheduleTasks();
+    }
     return p3p;
   }
 
@@ -115,34 +123,12 @@ class P3p {
   }
 
   Future<void> listen() async {
-    var router = Router();
-    router.post("/", (Request request) async {
-      final body = await request.readAsString();
-      final userI = await Event.tryProcess(this, body);
-      if (userI == null) {
-        return Response(
-          404,
-          body: JsonEncoder.withIndent('    ').convert(
-            [
-              (Event(
-                eventType: EventType.introduceRequest,
-                destinationPublicKey: ToOne(),
-              )..data = EventIntroduceRequest(
-                      endpoint: (await getSelfInfo()).endpoint,
-                      publickey: privateKey.toPublic,
-                    ).toJson())
-                  .toJson(),
-            ],
-          ),
-        );
-      }
-      return Response(
-        200,
-        body: await userI.relayEventsString(this),
-      );
-    });
     try {
-      final server = await io.serve(router, '0.0.0.0', 3893);
+      final server = await io.serve(
+        ReachableLocal.getListenRouter(this),
+        '0.0.0.0',
+        3893,
+      );
 
       print('${server.address.address}:${server.port}');
     } catch (e) {
@@ -151,91 +137,61 @@ class P3p {
   }
 
   bool isScheduleTasksCalled = false;
-  void scheduleTasks() async {
+  void _scheduleTasks() async {
     if (isScheduleTasksCalled) {
       print("scheduleTasks called more than once. this is unacceptable");
       return;
     }
-    isScheduleTasksCalled = true;
-    Timer.periodic(
-      Duration(seconds: 5),
-      (Timer t) async {
-        UserInfo si = await pingRelay();
-        si.save(this);
-        si.relayEvents(this, si.publicKey);
-        await processTasks(si);
-      },
-    );
+    scheduleTasks(this);
   }
 
-  Future<void> processTasks(UserInfo si) async {
-    for (UserInfo ui in userInfoBox.getAll()) {
-      print("schedTask: ${ui.id} - ${si.id}");
-      if (ui.id == si.id) continue;
-      // begin file request
-      final fs = await ui.fileStore.getFileStoreElement(this);
-      for (var felm in fs) {
-        if (felm.isDeleted == false &&
-            await felm.file.length() != felm.sizeBytes &&
-            felm.shouldFetch == true &&
-            felm.requestedLatestVersion == false) {
-          felm.requestedLatestVersion = true;
-          await felm.save(this);
-          ui.addEvent(
-            this,
-            Event(
-              eventType: EventType.fileRequest,
-              destinationPublicKey: ToOne(targetId: ui.publicKey.id),
-            )..data = EventFileRequest(
-                uuid: felm.uuid,
-              ).toJson(),
-          );
-          ui.save(this);
-        }
-      }
-      // end file request
-      final diff = DateTime.now().difference(ui.lastIntroduce).inMinutes;
-      print('p3p: ${ui.publicKey.fingerprint} : scheduleTasks diff = $diff');
-      if (diff > 60) {
-        ui.addEvent(
-          this,
-          Event(
-            eventType: EventType.introduce,
-            destinationPublicKey: ToOne(target: ui.publicKey),
-          )..data = EventIntroduce(
-              endpoint: si.endpoint,
-              fselm: await ui.fileStore.getFileStoreElement(this),
-              publickey: privateKey.toPublic,
-              username: si.name ?? "unknown name [${DateTime.now()}]",
-            ).toJson(),
-        );
-        ui.lastIntroduce = DateTime.now();
-      } else {
-        ui.relayEvents(this, ui.publicKey);
-      }
-      ui.save(this);
+  List<void Function(P3p p3p, Message msg, UserInfo user)> onMessageCallback =
+      [];
+  void callOnMessage(Message msg) {
+    final ui = getUserInfo(msg.roomFingerprint);
+    if (ui == null) {
+      print('callOnMessage: warn: user with fingerprint ${msg.roomFingerprint} '
+          'doesn\'t exist. I\'ll not call any callbacks.');
+      return;
+    }
+    for (final fn in onMessageCallback) {
+      fn(this, msg, ui);
     }
   }
 
-  Future<UserInfo> pingRelay() async {
-    final si = await getSelfInfo();
-    if (DateTime.now().difference(si.lastEvent).inSeconds < 15) {
-      si.addEvent(
-        this,
-        Event(
-          eventType: EventType.unimplemented,
-          destinationPublicKey: ToOne(targetId: si.publicKey.id),
-        ),
-      );
+  /// true - event will be deleted afterwards, while being marked
+  /// as executed
+  /// false - continue normal exacution
+  /// in a situation where we have many callbacks present every
+  /// sigle one will be called, no matter the boolean result of
+  /// previous one.
+  /// This function **is** blocking, entire loop will not continue
+  /// execution untill you resolve all Futures
+  /// However if new event arrives it will execute normally.
+  /// Avoid long blocking of events to not render your peer
+  /// unresponsive or to not have out of sync events in database.
+  List<Future<bool> Function(P3p p3p, Event evt)> onEventCallback = [];
+  Future<bool> callOnEvent(Event evt) async {
+    bool toRet = false;
+    for (final fn in onEventCallback) {
+      if (await fn(this, evt)) toRet = true;
     }
-    return si;
+    return toRet;
   }
 
-  void callOnMessage(Message msg) {
-    for (var fn in onMessageCallback) {
-      fn(this, msg);
+  /// onFileStoreElementCallback functions are being called once a
+  /// FileStoreElement().save() function is called,
+  /// that is
+  ///  - when user edits the file
+  ///  - when file is updated by event
+  ///  - at some other points too
+  /// If you want to block file edit or intercept it you should be
+  /// using onEventCallback (in most cases)
+  List<void Function(P3p p3p, FileStore fs, FileStoreElement fselm)>
+      onFileStoreElementCallback = [];
+  void callOnFileStoreElement(FileStore fs, FileStoreElement fselm) {
+    for (final fn in onFileStoreElementCallback) {
+      fn.call(this, fs, fselm);
     }
   }
-
-  List<Function(P3p p3p, Message msg)> onMessageCallback = [];
 }
diff --git i/lib/src/reachable/local.dart w/lib/src/reachable/local.dart
index f076170..35bef10 100644
--- i/lib/src/reachable/local.dart
+++ w/lib/src/reachable/local.dart
@@ -1,10 +1,45 @@
+import 'dart:convert';
+
 import 'package:dio/dio.dart';
 import 'package:p3p/p3p.dart';
 import 'package:p3p/src/reachable/abstract.dart';
+import 'package:shelf/shelf.dart' as shelf;
+import 'package:shelf_router/shelf_router.dart' as shell_router;
 
 final localDio = Dio(BaseOptions(receiveDataWhenStatusError: true));
 
 class ReachableLocal implements Reachable {
+  static shell_router.Router getListenRouter(P3p p3p) {
+    var router = shell_router.Router();
+    router.post("/", (shelf.Request request) async {
+      final body = await request.readAsString();
+      final userI = await Event.tryProcess(p3p, body);
+      if (userI == null) {
+        return shelf.Response(
+          404,
+          body: JsonEncoder.withIndent('    ').convert(
+            [
+              (Event(
+                eventType: EventType.introduceRequest,
+                destinationPublicKey: ToOne(),
+              )..data = EventIntroduceRequest(
+                      endpoint: (await p3p.getSelfInfo()).endpoint,
+                      publickey: p3p.privateKey.toPublic,
+                    ).toJson())
+                  .toJson(),
+            ],
+          ),
+        );
+      }
+      return shelf.Response(
+        200,
+        // ignore: deprecated_member_use_from_same_package
+        body: await userI.relayEventsString(p3p),
+      );
+    });
+    return router;
+  }
+
   static List<Endpoint> defaultEndpoints = [
     Endpoint(protocol: "local", host: "127.0.0.1:3893", extra: "")
   ];
diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
index 7e888b0..915e13c 100644
--- i/lib/src/reachable/relay.dart
+++ w/lib/src/reachable/relay.dart
@@ -10,6 +10,29 @@ final relayDio = Dio(BaseOptions(receiveDataWhenStatusError: true));
 Map<String, pgp.PublicKey> pkMap = {};
 
 class ReachableRelay implements Reachable {
+  static Future<void> getAndProcessEvents(P3p p3p) async {
+    for (var endp in defaultEndpoints) {
+      final resp = await _contactRelay(
+        endp: endp,
+        httpHostname:
+            "${_hostnameRoot(endp)}/${List.filled(p3p.privateKey.fingerprint.length, '0').join("")}",
+        p3p: p3p,
+        message: (await pgp.OpenPGP.encrypt(
+          pgp.Message.createTextMessage("{}"),
+          signingKeys: [p3p.privateKey],
+          encryptionKeys: [p3p.privateKey.toPublic],
+        ))
+            .armor(),
+      );
+      if (resp == null) {
+        print(
+            "ReachableRelay: getEvents(): unable to reach ${endp.toString()}");
+        continue;
+      }
+      Event.tryProcess(p3p, resp.data);
+    }
+  }
+
   static List<Endpoint> defaultEndpoints = [
     Endpoint(protocol: "relay", host: "mrcyjanek.net:3847", extra: ""),
   ];
@@ -31,43 +54,30 @@ class ReachableRelay implements Reachable {
             "scheme ${endpoint.protocol} is not supported by ReachableRelay (${protocols.toString()})",
       );
     }
-    final host =
-        "http${endpoint.protocol == "relays" ? 's' : ''}://${endpoint.host}/${publicKey.fingerprint}";
-    Response? resp;
-    try {
-      resp = await relayDio.post(
-        host,
-        options: Options(headers: {
-          "gpg-auth": base64.encode(
-            utf8.encode(
-              await generateAuth(endpoint, p3p.privateKey),
-            ),
-          ),
-        }),
-        data: message,
-      );
-    } catch (e) {
-      if (e is DioException) {
-        print((e).response);
-      } else {
-        print(e);
-      }
+    Response? resp = await _contactRelay(
+      endp: endpoint,
+      httpHostname: _httpHostname(endpoint, publicKey),
+      p3p: p3p,
+      message: message,
+    );
+    if (resp == null) {
+      print("ReachableRelay: reach(): unable to reach ${endpoint.toString()}");
+      return P3pError(code: -1, info: "unable to reach 1");
     }
-    if (resp?.statusCode == 200) {
-      await Event.tryProcess(p3p, resp?.data);
+
+    if (resp.statusCode == 200) {
+      await Event.tryProcess(p3p, resp.data);
       return null;
     }
-    return P3pError(code: -1, info: "unable to reach");
+    return P3pError(code: -1, info: "unable to reach 2");
   }
 
-  Future<String> generateAuth(
+  static Future<String> generateAuth(
     Endpoint endpoint,
     pgp.PrivateKey privatekey,
   ) async {
-    print(endpoint);
     if (pkMap[endpoint.host] == null) {
-      final resp = await relayDio.get(
-          "http${endpoint.protocol == "relays" ? 's' : ''}://${endpoint.host}");
+      final resp = await relayDio.get(_hostnameRoot(endpoint));
       pkMap[endpoint.host] =
           await pgp.OpenPGP.readPublicKey(resp.data.toString());
       print(pkMap[endpoint.host]?.fingerprint);
@@ -88,4 +98,44 @@ class ReachableRelay implements Reachable {
     );
     return msg.armor();
   }
+
+  static Future<Response?> _contactRelay(
+      {required Endpoint endp,
+      required String httpHostname,
+      required P3p p3p,
+      dynamic message}) async {
+    assert(message != null);
+    try {
+      final resp = await relayDio.post(
+        httpHostname,
+        options: Options(headers: await _getHeaders(endp, p3p)),
+        data: message,
+      );
+      return resp;
+    } catch (e) {
+      if (e is DioException) {
+        print((e).response);
+        return e.response;
+      } else {
+        print(e);
+      }
+    }
+    return null;
+  }
+
+  static Future<Map<String, dynamic>> _getHeaders(
+      Endpoint endp, P3p p3p) async {
+    return {
+      "gpg-auth": base64.encode(
+        utf8.encode(
+          await generateAuth(endp, p3p.privateKey),
+        ),
+      ),
+    };
+  }
+
+  static String _httpHostname(Endpoint endp, PublicKey publicKey) =>
+      "${_hostnameRoot(endp)}/${publicKey.fingerprint}";
+  static String _hostnameRoot(Endpoint endp) =>
+      "http${endp.protocol == "relays" ? 's' : ''}://${endp.host}";
 }
diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
index 7ca62b0..a0ca347 100644
--- i/lib/src/userinfo.dart
+++ w/lib/src/userinfo.dart
@@ -54,7 +54,7 @@ class UserInfo {
         .query(Event_.destinationPublicKey.equals(destination.id))
         .build()
         .find()
-        .take(4)
+        .take(8)
         .toList();
   }
 
@@ -73,7 +73,7 @@ class UserInfo {
   FileStore get fileStore => FileStore(roomFingerprint: publicKey.fingerprint);
 
   void save(P3p p3p) {
-    p3p.userInfoBox.put(this);
+    id = p3p.userInfoBox.put(this);
   }
 
   Future<List<Message>> getMessages(P3p p3p) async {
@@ -102,22 +102,22 @@ class UserInfo {
   }
 
   Future<void> relayEvents(P3p p3p, PublicKey publicKey) async {
-    print("relayEvents");
+    // print("relayEvents");
     if (endpoint.isEmpty) {
-      print("hot fixing endpoint by adding ReachableRelay.defaultEndpoints");
+      print("fixing endpoint by adding ReachableRelay.defaultEndpoints");
       endpoint = ReachableRelay.defaultEndpoints;
     }
     final evts = getEvents(p3p, publicKey);
 
     if (evts.isEmpty) {
-      print("ignoring because event list is empty");
+      // print("ignoring because event list is empty");
       return;
     }
-    bool canRelayBulk = true;
-    if (!canRelayBulk) return;
+    // bool canRelayBulk = true;
+    // if (!canRelayBulk) return;
 
     for (var evt in evts) {
-      print("evts ${evt.id}:${evt.toJson()}");
+      // print("evts ${evt.id}:${evt.toJson()}");
     }
     final bodyJson = JsonEncoder.withIndent('    ').convert(evts);
 
@@ -158,11 +158,12 @@ class UserInfo {
     }
   }
 
-  @Deprecated('NOTE: If you call this function event is being set internally as'
-      'delivered, it is your problem to hand it over to the user.'
-      'desired location.'
-      'For this reason this is released as deprecated - to discourage'
-      'usage.')
+  @Deprecated(
+      'NOTE: If you call this function event is being set internally as '
+      'delivered, it is your problem to hand it over to the user. '
+      'desired location. \n'
+      'For this reason this is released as deprecated - to discourage '
+      'usage. ')
   Future<String> relayEventsString(
     P3p p3p,
   ) async {
diff --git i/lib/src/userinfossmdc.dart w/lib/src/userinfossmdc.dart
index a3befdd..975f7b8 100644
--- i/lib/src/userinfossmdc.dart
+++ w/lib/src/userinfossmdc.dart
@@ -73,18 +73,33 @@ class UserInfoSSMDC implements UserInfo {
   }
 
   @override
-  Future<void> addMessage(P3p p3p, Message message) {
-    // TODO: implement addMessage
-    throw UnimplementedError();
+  Future<void> addMessage(P3p p3p, Message message) async {
+    final msg = p3p.messageBox
+        .query(Message_.uuid
+            .equals(message.uuid)
+            .and(Message_.roomFingerprint.equals(publicKey.fingerprint)))
+        .build()
+        .findFirst();
+    if (msg != null) {
+      message.id = msg.id;
+    }
+    p3p.messageBox.put(message);
+    p3p.callOnMessage(message);
   }
 
   @override
   FileStore get fileStore => FileStore(roomFingerprint: publicKey.fingerprint);
 
   @override
-  Future<List<Message>> getMessages(P3p p3p) {
-    // TODO: implement getMessages
-    throw UnimplementedError();
+  Future<List<Message>> getMessages(P3p p3p) async {
+    final ret = p3p.messageBox
+        .query(Message_.roomFingerprint.equals(publicKey.fingerprint))
+        .build()
+        .find();
+    ret.sort(
+      (m1, m2) => m1.dateReceived.difference(m2.dateReceived).inMicroseconds,
+    );
+    return ret;
   }
 
   @override
@@ -95,14 +110,19 @@ class UserInfoSSMDC implements UserInfo {
   }
 
   @override
+  @Deprecated("relayEventsString: doesn't work in SSMDC implementation, due "
+      "to the nature of the requests and the protocol, we are simply returning "
+      "an empty string to not break the compatibility. But refrain from using "
+      "it in future. A better approach needs to be put in place to deliver "
+      "events in a bi-directional way.")
   Future<String> relayEventsString(P3p p3p) async {
-    print("relayEventsString: not implemented, and probable never will be.");
+    print("[ssmdc] relayEventsString: not implemented");
     return "";
   }
 
   @override
   void save(P3p p3p) {
-    // TODO: implement save
+    p3p.userInfoSSMDCBox.put(this);
   }
 
   @override
no changes added to commit (use "git add" and/or "git commit -a")


$ p3pch4t 

--------

On branch master
Your branch is ahead of 'origin/master' by 1 commit.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   android/app/src/main/AndroidManifest.xml
	modified:   assets/git-changes.md
	modified:   lib/main.dart
	modified:   lib/pages/adduser.dart
	modified:   lib/pages/chatpage.dart
	modified:   lib/pages/filemanager.dart
	modified:   lib/pages/fileview.dart
	modified:   lib/pages/home.dart
	modified:   lib/pages/landing.dart
	modified:   lib/pages/webxdcfileview.dart
	modified:   lib/pages/webxdcfileview_android.dart
	modified:   macos/Flutter/GeneratedPluginRegistrant.swift
	modified:   pubspec.lock
	modified:   pubspec.yaml
	deleted:    test/widget_test.dart

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	lib/consts.dart
	lib/pages/widgets/
	lib/service.dart

--------------------------------------------------
Changes not staged for commit:
diff --git i/android/app/src/main/AndroidManifest.xml w/android/app/src/main/AndroidManifest.xml
index 4986a6a..84a6b08 100644
--- i/android/app/src/main/AndroidManifest.xml
+++ w/android/app/src/main/AndroidManifest.xml
@@ -23,6 +23,7 @@
             <intent-filter>
                 <action android:name="android.intent.action.MAIN"/>
                 <category android:name="android.intent.category.LAUNCHER"/>
+                <category android:name="android.intent.category.BROWSABLE"/>
             </intent-filter>
         </activity>
         <!-- Don't delete the meta-data below.
diff --git i/assets/git-changes.md w/assets/git-changes.md
index e7a6fa6..518d81c 100644
--- i/assets/git-changes.md
+++ w/assets/git-changes.md
@@ -1 +1,753 @@
-If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.
\ No newline at end of file
+If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.
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
+	modified:   example/echobot/main.dart
+	modified:   example/ssmdc.v1/main.dart
+	modified:   lib/src/event.dart
+	modified:   lib/src/filestore.dart
+	modified:   lib/src/p3p_base.dart
+	modified:   lib/src/reachable/local.dart
+	modified:   lib/src/reachable/relay.dart
+	modified:   lib/src/userinfo.dart
+	modified:   lib/src/userinfossmdc.dart
+
+Untracked files:
+  (use "git add <file>..." to include in what will be committed)
+	lib/src/background.dart
+
+--------------------------------------------------
+Changes not staged for commit:
+diff --git i/example/echobot/main.dart w/example/echobot/main.dart
+index 0416aab..fa1fb4f 100644
+--- i/example/echobot/main.dart
++++ w/example/echobot/main.dart
+@@ -34,12 +34,8 @@ void main() async {
+   // start processing new messages
+ }
+ 
+-void _messageCallback(P3p p3p, Message msg) {
+-  final sender = msg.getSender(p3p);
+-  p3p.sendMessage(
+-    sender,
+-    "I've received your message: ${msg.text}",
+-  );
++void _messageCallback(P3p p3p, Message msg, UserInfo user) {
++  p3p.sendMessage(user, "I've received your message: ${msg.text}");
+ }
+ 
+ Future<void> generatePrivkey(File storedPgp) async {
+diff --git i/example/ssmdc.v1/main.dart w/example/ssmdc.v1/main.dart
+index 9ecd845..c465235 100644
+--- i/example/ssmdc.v1/main.dart
++++ w/example/ssmdc.v1/main.dart
+@@ -34,12 +34,8 @@ void main() async {
+   // start processing new messages
+ }
+ 
+-void _messageCallback(P3p p3p, Message msg) {
+-  final sender = msg.getSender(p3p);
+-  p3p.sendMessage(
+-    sender,
+-    "I've received your message: ${msg.text}",
+-  );
++void _messageCallback(P3p p3p, Message msg, UserInfo ui) {
++  p3p.sendMessage(ui, "I've received your message: ${msg.text}");
+ }
+ 
+ Future<void> generatePrivkey(File storedPgp) async {
+diff --git i/lib/src/event.dart w/lib/src/event.dart
+index d1646bd..aee229e 100644
+--- i/lib/src/event.dart
++++ w/lib/src/event.dart
+@@ -114,7 +114,7 @@ class Event {
+         if (ui == null) {
+           tryProcess(p3p, payload);
+         } else {
+-          await element.process(ui, p3p);
++          element.process(ui, p3p);
+         }
+       }
+     }
+@@ -172,28 +172,32 @@ class Event {
+     return ret;
+   }
+ 
+-  Future<bool> process(UserInfo userInfo, P3p p3p) async {
+-    print("processing.. - ${userInfo.id} - ${userInfo.name} - $eventType");
+-    // JsonEncoder.withIndent('    ')
+-    //     .convert(toJson())
+-    //     .split("\n")
+-    //     .forEach((element) {
+-    //   print(element); // I hate the fact that flutter cuts the logs.
+-    // });
++  void process(UserInfo userInfo, P3p p3p) async {
++    print("processing: - ${userInfo.id} - ${userInfo.name} - $eventType");
++
++    if (await p3p.callOnEvent(this)) {
++      if (id != 0) {
++        p3p.eventBox.remove(id);
++      }
++      return;
++    }
++
+     switch (eventType) {
+       case EventType.introduce:
+-        return await processIntroduce(p3p);
++        processIntroduce(p3p);
+       case EventType.introduceRequest:
+-        return await processIntroduceRequest(p3p);
++        processIntroduceRequest(p3p);
+       case EventType.message:
+-        return await processMessage(p3p, userInfo);
++        processMessage(p3p, userInfo);
+       case EventType.fileRequest:
+-        return await processFileRequest(p3p, userInfo);
++        processFileRequest(p3p, userInfo);
+       case EventType.file:
+-        return await processFile(p3p, userInfo);
++        processFile(p3p, userInfo);
+       case EventType.unimplemented || null:
+         print("event: unimplemented");
+-        return false;
++    }
++    if (id != 0) {
++      p3p.eventBox.remove(id);
+     }
+   }
+ 
+@@ -250,12 +254,14 @@ class Event {
+         }
+       }
+       if (!fileExisted) {
+-        await useri.fileStore.putFileStoreElement(p3p,
+-            localFile: null,
+-            localFileSha512sum: elm["sha512sum"],
+-            sizeBytes: elm["sizeBytes"],
+-            fileInChatPath: elm["path"],
+-            uuid: elm["uuid"]);
++        await useri.fileStore.putFileStoreElement(
++          p3p,
++          localFile: null,
++          localFileSha512sum: elm["sha512sum"],
++          sizeBytes: elm["sizeBytes"],
++          fileInChatPath: elm["path"],
++          uuid: elm["uuid"],
++        );
+       }
+     }
+ 
+diff --git i/lib/src/filestore.dart w/lib/src/filestore.dart
+index 7636814..5e68549 100644
+--- i/lib/src/filestore.dart
++++ w/lib/src/filestore.dart
+@@ -70,7 +70,15 @@ class FileStoreElement {
+         useri.save(p3p);
+       }
+     }
++    if (p.basename(path).endsWith('xdc') ||
++        p.basename(path).endsWith('.jsonp')) {
++      shouldFetch = true;
++    }
+     p3p.fileStoreElementBox.put(this);
++    p3p.callOnFileStoreElement(
++      FileStore(roomFingerprint: roomFingerprint),
++      this,
++    );
+   }
+ 
+   Future<void> updateContent(
+@@ -108,7 +116,9 @@ class FileStore {
+ 
+   Future<List<FileStoreElement>> getFileStoreElement(P3p p3p) async {
+     return p3p.fileStoreElementBox
+-        .query(FileStoreElement_.roomFingerprint.equals(roomFingerprint))
++        .query(FileStoreElement_.roomFingerprint
++            .equals(roomFingerprint)
++            .and(FileStoreElement_.isDeleted.equals(false)))
+         .build()
+         .find();
+   }
+diff --git i/lib/src/p3p_base.dart w/lib/src/p3p_base.dart
+index a2ed1c4..2f82d66 100644
+--- i/lib/src/p3p_base.dart
++++ w/lib/src/p3p_base.dart
+@@ -1,23 +1,24 @@
+ import 'dart:async';
+-import 'dart:convert';
+ import 'dart:io';
+ 
+ import 'package:p3p/objectbox.g.dart';
++import 'package:p3p/src/background.dart';
+ import 'package:p3p/src/chat.dart';
+ import 'package:p3p/src/endpoint.dart';
+ import 'package:p3p/src/error.dart';
+ import 'package:p3p/src/event.dart';
+ import 'package:p3p/src/filestore.dart';
+ import 'package:p3p/src/publickey.dart';
++import 'package:p3p/src/reachable/local.dart';
+ import 'package:p3p/src/reachable/relay.dart';
+ import 'package:p3p/src/userinfo.dart';
+ import 'package:dart_pg/dart_pg.dart' as pgp;
+ import 'package:p3p/src/userinfossmdc.dart';
+-import 'package:shelf/shelf.dart';
+ import 'package:shelf/shelf_io.dart' as io;
+-import 'package:shelf_router/shelf_router.dart';
+ import 'package:path/path.dart' as p;
+ 
++bool storeIsOpen = false;
++
+ class P3p {
+   P3p({
+     required this.privateKey,
+@@ -43,21 +44,28 @@ class P3p {
+     String privateKeyPassword,
+   ) async {
+     print("p3p: using $storePath");
++    final dbPath = Directory(p.join(storePath, 'dbv2'));
++    if (!await dbPath.exists()) await dbPath.create(recursive: true);
+ 
+     final privkey = await (await pgp.OpenPGP.readPrivateKey(privateKey))
+         .decrypt(privateKeyPassword);
+-
+-    final dbPath = Directory(p.join(storePath, 'dbv2'));
+-    if (!await dbPath.exists()) await dbPath.create(recursive: true);
++    if (storeIsOpen == false) {
++      storeIsOpen = Store.isOpen(dbPath.absolute.path);
++    }
++    final newStore = storeIsOpen
++        ? Store.attach(getObjectBoxModel(), dbPath.absolute.path)
++        : openStore(
++            directory: dbPath.absolute.path,
++          );
+     final p3p = P3p(
+       privateKey: privkey,
+       fileStorePath: p.join(storePath, 'files'),
+-      store: openStore(
+-        directory: dbPath.absolute.path,
+-      ),
++      store: newStore,
+     );
+-    await p3p.listen();
+-    p3p.scheduleTasks();
++    if (!storeIsOpen) {
++      await p3p.listen();
++      p3p._scheduleTasks();
++    }
+     return p3p;
+   }
+ 
+@@ -115,34 +123,12 @@ class P3p {
+   }
+ 
+   Future<void> listen() async {
+-    var router = Router();
+-    router.post("/", (Request request) async {
+-      final body = await request.readAsString();
+-      final userI = await Event.tryProcess(this, body);
+-      if (userI == null) {
+-        return Response(
+-          404,
+-          body: JsonEncoder.withIndent('    ').convert(
+-            [
+-              (Event(
+-                eventType: EventType.introduceRequest,
+-                destinationPublicKey: ToOne(),
+-              )..data = EventIntroduceRequest(
+-                      endpoint: (await getSelfInfo()).endpoint,
+-                      publickey: privateKey.toPublic,
+-                    ).toJson())
+-                  .toJson(),
+-            ],
+-          ),
+-        );
+-      }
+-      return Response(
+-        200,
+-        body: await userI.relayEventsString(this),
+-      );
+-    });
+     try {
+-      final server = await io.serve(router, '0.0.0.0', 3893);
++      final server = await io.serve(
++        ReachableLocal.getListenRouter(this),
++        '0.0.0.0',
++        3893,
++      );
+ 
+       print('${server.address.address}:${server.port}');
+     } catch (e) {
+@@ -151,91 +137,61 @@ class P3p {
+   }
+ 
+   bool isScheduleTasksCalled = false;
+-  void scheduleTasks() async {
++  void _scheduleTasks() async {
+     if (isScheduleTasksCalled) {
+       print("scheduleTasks called more than once. this is unacceptable");
+       return;
+     }
+-    isScheduleTasksCalled = true;
+-    Timer.periodic(
+-      Duration(seconds: 5),
+-      (Timer t) async {
+-        UserInfo si = await pingRelay();
+-        si.save(this);
+-        si.relayEvents(this, si.publicKey);
+-        await processTasks(si);
+-      },
+-    );
++    scheduleTasks(this);
+   }
+ 
+-  Future<void> processTasks(UserInfo si) async {
+-    for (UserInfo ui in userInfoBox.getAll()) {
+-      print("schedTask: ${ui.id} - ${si.id}");
+-      if (ui.id == si.id) continue;
+-      // begin file request
+-      final fs = await ui.fileStore.getFileStoreElement(this);
+-      for (var felm in fs) {
+-        if (felm.isDeleted == false &&
+-            await felm.file.length() != felm.sizeBytes &&
+-            felm.shouldFetch == true &&
+-            felm.requestedLatestVersion == false) {
+-          felm.requestedLatestVersion = true;
+-          await felm.save(this);
+-          ui.addEvent(
+-            this,
+-            Event(
+-              eventType: EventType.fileRequest,
+-              destinationPublicKey: ToOne(targetId: ui.publicKey.id),
+-            )..data = EventFileRequest(
+-                uuid: felm.uuid,
+-              ).toJson(),
+-          );
+-          ui.save(this);
+-        }
+-      }
+-      // end file request
+-      final diff = DateTime.now().difference(ui.lastIntroduce).inMinutes;
+-      print('p3p: ${ui.publicKey.fingerprint} : scheduleTasks diff = $diff');
+-      if (diff > 60) {
+-        ui.addEvent(
+-          this,
+-          Event(
+-            eventType: EventType.introduce,
+-            destinationPublicKey: ToOne(target: ui.publicKey),
+-          )..data = EventIntroduce(
+-              endpoint: si.endpoint,
+-              fselm: await ui.fileStore.getFileStoreElement(this),
+-              publickey: privateKey.toPublic,
+-              username: si.name ?? "unknown name [${DateTime.now()}]",
+-            ).toJson(),
+-        );
+-        ui.lastIntroduce = DateTime.now();
+-      } else {
+-        ui.relayEvents(this, ui.publicKey);
+-      }
+-      ui.save(this);
++  List<void Function(P3p p3p, Message msg, UserInfo user)> onMessageCallback =
++      [];
++  void callOnMessage(Message msg) {
++    final ui = getUserInfo(msg.roomFingerprint);
++    if (ui == null) {
++      print('callOnMessage: warn: user with fingerprint ${msg.roomFingerprint} '
++          'doesn\'t exist. I\'ll not call any callbacks.');
++      return;
++    }
++    for (final fn in onMessageCallback) {
++      fn(this, msg, ui);
+     }
+   }
+ 
+-  Future<UserInfo> pingRelay() async {
+-    final si = await getSelfInfo();
+-    if (DateTime.now().difference(si.lastEvent).inSeconds < 15) {
+-      si.addEvent(
+-        this,
+-        Event(
+-          eventType: EventType.unimplemented,
+-          destinationPublicKey: ToOne(targetId: si.publicKey.id),
+-        ),
+-      );
++  /// true - event will be deleted afterwards, while being marked
++  /// as executed
++  /// false - continue normal exacution
++  /// in a situation where we have many callbacks present every
++  /// sigle one will be called, no matter the boolean result of
++  /// previous one.
++  /// This function **is** blocking, entire loop will not continue
++  /// execution untill you resolve all Futures
++  /// However if new event arrives it will execute normally.
++  /// Avoid long blocking of events to not render your peer
++  /// unresponsive or to not have out of sync events in database.
++  List<Future<bool> Function(P3p p3p, Event evt)> onEventCallback = [];
++  Future<bool> callOnEvent(Event evt) async {
++    bool toRet = false;
++    for (final fn in onEventCallback) {
++      if (await fn(this, evt)) toRet = true;
+     }
+-    return si;
++    return toRet;
+   }
+ 
+-  void callOnMessage(Message msg) {
+-    for (var fn in onMessageCallback) {
+-      fn(this, msg);
++  /// onFileStoreElementCallback functions are being called once a
++  /// FileStoreElement().save() function is called,
++  /// that is
++  ///  - when user edits the file
++  ///  - when file is updated by event
++  ///  - at some other points too
++  /// If you want to block file edit or intercept it you should be
++  /// using onEventCallback (in most cases)
++  List<void Function(P3p p3p, FileStore fs, FileStoreElement fselm)>
++      onFileStoreElementCallback = [];
++  void callOnFileStoreElement(FileStore fs, FileStoreElement fselm) {
++    for (final fn in onFileStoreElementCallback) {
++      fn.call(this, fs, fselm);
+     }
+   }
+-
+-  List<Function(P3p p3p, Message msg)> onMessageCallback = [];
+ }
+diff --git i/lib/src/reachable/local.dart w/lib/src/reachable/local.dart
+index f076170..35bef10 100644
+--- i/lib/src/reachable/local.dart
++++ w/lib/src/reachable/local.dart
+@@ -1,10 +1,45 @@
++import 'dart:convert';
++
+ import 'package:dio/dio.dart';
+ import 'package:p3p/p3p.dart';
+ import 'package:p3p/src/reachable/abstract.dart';
++import 'package:shelf/shelf.dart' as shelf;
++import 'package:shelf_router/shelf_router.dart' as shell_router;
+ 
+ final localDio = Dio(BaseOptions(receiveDataWhenStatusError: true));
+ 
+ class ReachableLocal implements Reachable {
++  static shell_router.Router getListenRouter(P3p p3p) {
++    var router = shell_router.Router();
++    router.post("/", (shelf.Request request) async {
++      final body = await request.readAsString();
++      final userI = await Event.tryProcess(p3p, body);
++      if (userI == null) {
++        return shelf.Response(
++          404,
++          body: JsonEncoder.withIndent('    ').convert(
++            [
++              (Event(
++                eventType: EventType.introduceRequest,
++                destinationPublicKey: ToOne(),
++              )..data = EventIntroduceRequest(
++                      endpoint: (await p3p.getSelfInfo()).endpoint,
++                      publickey: p3p.privateKey.toPublic,
++                    ).toJson())
++                  .toJson(),
++            ],
++          ),
++        );
++      }
++      return shelf.Response(
++        200,
++        // ignore: deprecated_member_use_from_same_package
++        body: await userI.relayEventsString(p3p),
++      );
++    });
++    return router;
++  }
++
+   static List<Endpoint> defaultEndpoints = [
+     Endpoint(protocol: "local", host: "127.0.0.1:3893", extra: "")
+   ];
+diff --git i/lib/src/reachable/relay.dart w/lib/src/reachable/relay.dart
+index 7e888b0..915e13c 100644
+--- i/lib/src/reachable/relay.dart
++++ w/lib/src/reachable/relay.dart
+@@ -10,6 +10,29 @@ final relayDio = Dio(BaseOptions(receiveDataWhenStatusError: true));
+ Map<String, pgp.PublicKey> pkMap = {};
+ 
+ class ReachableRelay implements Reachable {
++  static Future<void> getAndProcessEvents(P3p p3p) async {
++    for (var endp in defaultEndpoints) {
++      final resp = await _contactRelay(
++        endp: endp,
++        httpHostname:
++            "${_hostnameRoot(endp)}/${List.filled(p3p.privateKey.fingerprint.length, '0').join("")}",
++        p3p: p3p,
++        message: (await pgp.OpenPGP.encrypt(
++          pgp.Message.createTextMessage("{}"),
++          signingKeys: [p3p.privateKey],
++          encryptionKeys: [p3p.privateKey.toPublic],
++        ))
++            .armor(),
++      );
++      if (resp == null) {
++        print(
++            "ReachableRelay: getEvents(): unable to reach ${endp.toString()}");
++        continue;
++      }
++      Event.tryProcess(p3p, resp.data);
++    }
++  }
++
+   static List<Endpoint> defaultEndpoints = [
+     Endpoint(protocol: "relay", host: "mrcyjanek.net:3847", extra: ""),
+   ];
+@@ -31,43 +54,30 @@ class ReachableRelay implements Reachable {
+             "scheme ${endpoint.protocol} is not supported by ReachableRelay (${protocols.toString()})",
+       );
+     }
+-    final host =
+-        "http${endpoint.protocol == "relays" ? 's' : ''}://${endpoint.host}/${publicKey.fingerprint}";
+-    Response? resp;
+-    try {
+-      resp = await relayDio.post(
+-        host,
+-        options: Options(headers: {
+-          "gpg-auth": base64.encode(
+-            utf8.encode(
+-              await generateAuth(endpoint, p3p.privateKey),
+-            ),
+-          ),
+-        }),
+-        data: message,
+-      );
+-    } catch (e) {
+-      if (e is DioException) {
+-        print((e).response);
+-      } else {
+-        print(e);
+-      }
++    Response? resp = await _contactRelay(
++      endp: endpoint,
++      httpHostname: _httpHostname(endpoint, publicKey),
++      p3p: p3p,
++      message: message,
++    );
++    if (resp == null) {
++      print("ReachableRelay: reach(): unable to reach ${endpoint.toString()}");
++      return P3pError(code: -1, info: "unable to reach 1");
+     }
+-    if (resp?.statusCode == 200) {
+-      await Event.tryProcess(p3p, resp?.data);
++
++    if (resp.statusCode == 200) {
++      await Event.tryProcess(p3p, resp.data);
+       return null;
+     }
+-    return P3pError(code: -1, info: "unable to reach");
++    return P3pError(code: -1, info: "unable to reach 2");
+   }
+ 
+-  Future<String> generateAuth(
++  static Future<String> generateAuth(
+     Endpoint endpoint,
+     pgp.PrivateKey privatekey,
+   ) async {
+-    print(endpoint);
+     if (pkMap[endpoint.host] == null) {
+-      final resp = await relayDio.get(
+-          "http${endpoint.protocol == "relays" ? 's' : ''}://${endpoint.host}");
++      final resp = await relayDio.get(_hostnameRoot(endpoint));
+       pkMap[endpoint.host] =
+           await pgp.OpenPGP.readPublicKey(resp.data.toString());
+       print(pkMap[endpoint.host]?.fingerprint);
+@@ -88,4 +98,44 @@ class ReachableRelay implements Reachable {
+     );
+     return msg.armor();
+   }
++
++  static Future<Response?> _contactRelay(
++      {required Endpoint endp,
++      required String httpHostname,
++      required P3p p3p,
++      dynamic message}) async {
++    assert(message != null);
++    try {
++      final resp = await relayDio.post(
++        httpHostname,
++        options: Options(headers: await _getHeaders(endp, p3p)),
++        data: message,
++      );
++      return resp;
++    } catch (e) {
++      if (e is DioException) {
++        print((e).response);
++        return e.response;
++      } else {
++        print(e);
++      }
++    }
++    return null;
++  }
++
++  static Future<Map<String, dynamic>> _getHeaders(
++      Endpoint endp, P3p p3p) async {
++    return {
++      "gpg-auth": base64.encode(
++        utf8.encode(
++          await generateAuth(endp, p3p.privateKey),
++        ),
++      ),
++    };
++  }
++
++  static String _httpHostname(Endpoint endp, PublicKey publicKey) =>
++      "${_hostnameRoot(endp)}/${publicKey.fingerprint}";
++  static String _hostnameRoot(Endpoint endp) =>
++      "http${endp.protocol == "relays" ? 's' : ''}://${endp.host}";
+ }
+diff --git i/lib/src/userinfo.dart w/lib/src/userinfo.dart
+index 7ca62b0..a0ca347 100644
+--- i/lib/src/userinfo.dart
++++ w/lib/src/userinfo.dart
+@@ -54,7 +54,7 @@ class UserInfo {
+         .query(Event_.destinationPublicKey.equals(destination.id))
+         .build()
+         .find()
+-        .take(4)
++        .take(8)
+         .toList();
+   }
+ 
+@@ -73,7 +73,7 @@ class UserInfo {
+   FileStore get fileStore => FileStore(roomFingerprint: publicKey.fingerprint);
+ 
+   void save(P3p p3p) {
+-    p3p.userInfoBox.put(this);
++    id = p3p.userInfoBox.put(this);
+   }
+ 
+   Future<List<Message>> getMessages(P3p p3p) async {
+@@ -102,22 +102,22 @@ class UserInfo {
+   }
+ 
+   Future<void> relayEvents(P3p p3p, PublicKey publicKey) async {
+-    print("relayEvents");
++    // print("relayEvents");
+     if (endpoint.isEmpty) {
+-      print("hot fixing endpoint by adding ReachableRelay.defaultEndpoints");
++      print("fixing endpoint by adding ReachableRelay.defaultEndpoints");
+       endpoint = ReachableRelay.defaultEndpoints;
+     }
+     final evts = getEvents(p3p, publicKey);
+ 
+     if (evts.isEmpty) {
+-      print("ignoring because event list is empty");
++      // print("ignoring because event list is empty");
+       return;
+     }
+-    bool canRelayBulk = true;
+-    if (!canRelayBulk) return;
++    // bool canRelayBulk = true;
++    // if (!canRelayBulk) return;
+ 
+     for (var evt in evts) {
+-      print("evts ${evt.id}:${evt.toJson()}");
++      // print("evts ${evt.id}:${evt.toJson()}");
+     }
+     final bodyJson = JsonEncoder.withIndent('    ').convert(evts);
+ 
+@@ -158,11 +158,12 @@ class UserInfo {
+     }
+   }
+ 
+-  @Deprecated('NOTE: If you call this function event is being set internally as'
+-      'delivered, it is your problem to hand it over to the user.'
+-      'desired location.'
+-      'For this reason this is released as deprecated - to discourage'
+-      'usage.')
++  @Deprecated(
++      'NOTE: If you call this function event is being set internally as '
++      'delivered, it is your problem to hand it over to the user. '
++      'desired location. \n'
++      'For this reason this is released as deprecated - to discourage '
++      'usage. ')
+   Future<String> relayEventsString(
+     P3p p3p,
+   ) async {
+diff --git i/lib/src/userinfossmdc.dart w/lib/src/userinfossmdc.dart
+index a3befdd..975f7b8 100644
+--- i/lib/src/userinfossmdc.dart
++++ w/lib/src/userinfossmdc.dart
+@@ -73,18 +73,33 @@ class UserInfoSSMDC implements UserInfo {
+   }
+ 
+   @override
+-  Future<void> addMessage(P3p p3p, Message message) {
+-    // TODO: implement addMessage
+-    throw UnimplementedError();
++  Future<void> addMessage(P3p p3p, Message message) async {
++    final msg = p3p.messageBox
++        .query(Message_.uuid
++            .equals(message.uuid)
++            .and(Message_.roomFingerprint.equals(publicKey.fingerprint)))
++        .build()
++        .findFirst();
++    if (msg != null) {
++      message.id = msg.id;
++    }
++    p3p.messageBox.put(message);
++    p3p.callOnMessage(message);
+   }
+ 
+   @override
+   FileStore get fileStore => FileStore(roomFingerprint: publicKey.fingerprint);
+ 
+   @override
+-  Future<List<Message>> getMessages(P3p p3p) {
+-    // TODO: implement getMessages
+-    throw UnimplementedError();
++  Future<List<Message>> getMessages(P3p p3p) async {
++    final ret = p3p.messageBox
++        .query(Message_.roomFingerprint.equals(publicKey.fingerprint))
++        .build()
++        .find();
++    ret.sort(
++      (m1, m2) => m1.dateReceived.difference(m2.dateReceived).inMicroseconds,
++    );
++    return ret;
+   }
+ 
+   @override
+@@ -95,14 +110,19 @@ class UserInfoSSMDC implements UserInfo {
+   }
+ 
+   @override
++  @Deprecated("relayEventsString: doesn't work in SSMDC implementation, due "
++      "to the nature of the requests and the protocol, we are simply returning "
++      "an empty string to not break the compatibility. But refrain from using "
++      "it in future. A better approach needs to be put in place to deliver "
++      "events in a bi-directional way.")
+   Future<String> relayEventsString(P3p p3p) async {
+-    print("relayEventsString: not implemented, and probable never will be.");
++    print("[ssmdc] relayEventsString: not implemented");
+     return "";
+   }
+ 
+   @override
+   void save(P3p p3p) {
+-    // TODO: implement save
++    p3p.userInfoSSMDCBox.put(this);
+   }
+ 
+   @override
+no changes added to commit (use "git add" and/or "git commit -a")
+
+
+$ p3pch4t 
+
+--------
+
diff --git i/lib/main.dart w/lib/main.dart
index 2135e34..fa9f617 100644
--- i/lib/main.dart
+++ w/lib/main.dart
@@ -1,51 +1,39 @@
-import 'dart:io';
-
-import 'package:dart_pg/dart_pg.dart';
 import 'package:flutter/material.dart';
 import 'package:p3p/p3p.dart';
+import 'package:p3pch4t/consts.dart';
 import 'package:p3pch4t/pages/home.dart';
-import 'package:path_provider/path_provider.dart';
-import 'package:path/path.dart' as p;
+import 'package:p3pch4t/pages/landing.dart';
+import 'package:p3pch4t/service.dart';
+import 'package:permission_handler/permission_handler.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 
-late final P3p p3p;
+P3p? p3p;
 
 void main() async {
   WidgetsFlutterBinding.ensureInitialized();
-  final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
   final SharedPreferences prefs = await SharedPreferences.getInstance();
-
   if (prefs.getString("priv_key") == null) {
-    debugPrint("generating privkey...");
-    final privkey = await OpenPGP.generateKey(
-        ['name <user@example.org>'], 'no_passpharse',
-        rsaKeySize: RSAKeySize.s4096);
-    prefs.setString("priv_key", privkey.armor());
+    runApp(const MyApp(landing: true));
+    return;
   }
-  debugPrint("starting p3p...");
-
-  p3p = await P3p.createSession(
-    p.join(appDocumentsDir.path, "p3pch4t"),
-    prefs.getString("priv_key")!,
-    "no_passpharse",
-  );
-  runApp(const MyApp());
+  await Permission.notification.request();
+  await initializeService();
+  runApp(const MyApp(landing: false));
 }
 
 class MyApp extends StatelessWidget {
-  const MyApp({super.key});
-
-  // This widget is the root of your application.
+  const MyApp({super.key, required this.landing});
+  final bool landing;
   @override
   Widget build(BuildContext context) {
     return MaterialApp(
-      title: 'P3pCh4t',
+      title: 'P3pCh4t $P3PCH4T_VERSION',
       theme: ThemeData(
         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
         useMaterial3: true,
       ),
       darkTheme: ThemeData.dark(useMaterial3: true),
-      home: const HomePage(),
+      home: landing ? const LandingPage() : const HomePage(),
     );
   }
 }
diff --git i/lib/pages/adduser.dart w/lib/pages/adduser.dart
index 4afc04c..53f3871 100644
--- i/lib/pages/adduser.dart
+++ w/lib/pages/adduser.dart
@@ -17,7 +17,7 @@ class _AddUserPageState extends State<AddUserPage> {
 
   @override
   void initState() {
-    p3p.getSelfInfo().then((value) {
+    p3p!.getSelfInfo().then((value) {
       setState(() => selfUi = value);
     });
     super.initState();
@@ -50,7 +50,7 @@ class _AddUserPageState extends State<AddUserPage> {
             ),
             OutlinedButton(
               onPressed: () async {
-                final ui = await UserInfo.create(p3p, pkCtrl.text);
+                final ui = await UserInfo.create(p3p!, pkCtrl.text);
                 if (ui == null) {
                   return;
                 }
diff --git i/lib/pages/chatpage.dart w/lib/pages/chatpage.dart
index 1e157d3..ff2a603 100644
--- i/lib/pages/chatpage.dart
+++ w/lib/pages/chatpage.dart
@@ -21,11 +21,34 @@ class _ChatPageState extends State<ChatPage> {
   @override
   void initState() {
     loadMessages();
+    loadMessageCallback();
     super.initState();
   }
 
+  @override
+  void dispose() {
+    p3p!.onMessageCallback.removeAt(_messageCallbackIndex);
+    super.dispose();
+  }
+
+  int _messageCallbackIndex = -1;
+  void loadMessageCallback() {
+    p3p!.onMessageCallback.add(_messageCallback);
+    setState(() {
+      _messageCallbackIndex = p3p!.onMessageCallback.length - 1;
+    });
+  }
+
+  void _messageCallback(P3p p3p, Message msg, UserInfo ui) {
+    if (ui.id != userInfo.id) return; // only current open chat events
+    loadMessages();
+    Future.delayed(Duration.zero).then((value) => loadMessages());
+    Future.delayed(const Duration(seconds: 1)).then((value) => loadMessages());
+  }
+
   void loadMessages() async {
-    final newMsgs = await userInfo.getMessages(p3p);
+    final newMsgs = await userInfo.getMessages(p3p!);
+    if (!mounted) return;
     setState(() {
       msgs = newMsgs;
     });
@@ -87,7 +110,7 @@ class _ChatPageState extends State<ChatPage> {
             width: double.maxFinite,
             child: TextField(
               onSubmitted: (value) async {
-                await p3p.sendMessage(userInfo, msgCtrl.text,
+                await p3p!.sendMessage(userInfo, msgCtrl.text,
                     type: MessageType.text);
                 loadMessages();
                 msgCtrl.clear();
diff --git i/lib/pages/filemanager.dart w/lib/pages/filemanager.dart
index 972f4c8..9e41023 100644
--- i/lib/pages/filemanager.dart
+++ w/lib/pages/filemanager.dart
@@ -40,7 +40,7 @@ class _FileManagerState extends State<FileManager> {
   }
 
   void loadFiles() async {
-    final newFiles = await fileStore.getFileStoreElement(p3p);
+    final newFiles = await fileStore.getFileStoreElement(p3p!);
     setState(() {
       files = newFiles;
     });
@@ -90,7 +90,7 @@ class _FileManagerState extends State<FileManager> {
           String dateSlug =
               "${today.year.toString()}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
           await fileStore.putFileStoreElement(
-            p3p,
+            p3p!,
             localFile: File(file.path!),
             localFileSha512sum: FileStoreElement.calcSha512Sum(
                 await File(file.path!).readAsBytes()),
diff --git i/lib/pages/fileview.dart w/lib/pages/fileview.dart
index 2015860..c43af55 100644
--- i/lib/pages/fileview.dart
+++ w/lib/pages/fileview.dart
@@ -89,9 +89,11 @@ class _FileViewState extends State<FileView> {
   }
 
   Future<void> saveElement() async {
-    print('saveElement:');
+    if (kDebugMode) {
+      print('saveElement:');
+    }
     file.path = pathCtrl.text;
-    await file.save(p3p, shouldIntroduce: true);
+    await file.save(p3p!, shouldIntroduce: true);
     setState(() {});
   }
 }
diff --git i/lib/pages/home.dart w/lib/pages/home.dart
index 9440181..759c63c 100644
--- i/lib/pages/home.dart
+++ w/lib/pages/home.dart
@@ -4,7 +4,7 @@ import 'package:p3p/p3p.dart';
 import 'package:p3pch4t/pages/adduser.dart';
 import 'package:p3pch4t/pages/chatpage.dart';
 import 'package:p3pch4t/pages/userinfosettings.dart';
-import 'package:url_launcher/url_launcher.dart';
+import 'package:p3pch4t/pages/widgets/versionwidget.dart';
 
 class HomePage extends StatefulWidget {
   const HomePage({Key? key}) : super(key: key);
@@ -19,11 +19,38 @@ class _HomePageState extends State<HomePage> {
   @override
   void initState() {
     loadUsers();
+    loadEventCallback();
     super.initState();
   }
 
+  @override
+  void dispose() {
+    p3p!.onEventCallback.removeAt(_onEventCallbackIndex);
+    super.dispose();
+  }
+
+  int _onEventCallbackIndex = -1;
+
+  void loadEventCallback() {
+    p3p!.onEventCallback.add(_eventCallback);
+    setState(() {
+      _onEventCallbackIndex = p3p!.onEventCallback.length - 1;
+    });
+  }
+
+  Future<bool> _eventCallback(P3p p3p, Event evt) async {
+    if (evt.eventType != EventType.introduce) return false;
+    loadUsers();
+    Future.delayed(Duration.zero).then((value) => loadUsers());
+    Future.delayed(const Duration(seconds: 1)).then((value) => loadUsers());
+    // Why three times? Because I have no damn idea
+    // when will the event finish processing...
+    // I'll address that.. at some point.
+    return false;
+  }
+
   void loadUsers() async {
-    final value = await p3p.getUsers();
+    final value = await p3p!.getUsers();
     setState(() {
       users = value;
     });
@@ -39,24 +66,7 @@ class _HomePageState extends State<HomePage> {
       ),
       body: Column(
         children: [
-          if (updateAvailable)
-            Card(
-              child: ListTile(
-                title: const Text("New version is available!"),
-                subtitle: SizedBox(
-                  width: double.maxFinite,
-                  child: OutlinedButton(
-                    onPressed: () {
-                      launchUrl(
-                        Uri.parse("https://static.mrcyjanek.net/p3p/latest"),
-                        mode: LaunchMode.externalApplication,
-                      );
-                    },
-                    child: const Text("Update"),
-                  ),
-                ),
-              ),
-            ),
+          const VersionWidget(),
           Expanded(
             child: ListView.builder(
               itemCount: users.length,
@@ -67,8 +77,9 @@ class _HomePageState extends State<HomePage> {
                       await Navigator.of(context).push(
                         MaterialPageRoute(
                           builder: (context) => ChatPage(
-                            userInfo: p3p.getUserInfo(
-                                users[index].publicKey.fingerprint)!,
+                            userInfo: p3p!.getUserInfo(
+                              users[index].publicKey.fingerprint,
+                            )!,
                           ),
                         ),
                       );
@@ -79,8 +90,10 @@ class _HomePageState extends State<HomePage> {
                         MaterialPageRoute(
                           builder: (context) {
                             return UserInfoPage(
-                                userInfo: p3p.getUserInfo(
-                                    users[index].publicKey.fingerprint)!);
+                              userInfo: p3p!.getUserInfo(
+                                users[index].publicKey.fingerprint,
+                              )!,
+                            );
                           },
                         ),
                       );
diff --git i/lib/pages/landing.dart w/lib/pages/landing.dart
index b7199e6..255c356 100644
--- i/lib/pages/landing.dart
+++ w/lib/pages/landing.dart
@@ -1,10 +1,164 @@
+import 'dart:io';
+
+import 'package:dart_pg/dart_pg.dart';
 import 'package:flutter/material.dart';
+import 'package:p3pch4t/helpers.dart';
+import 'package:p3pch4t/pages/home.dart';
+import 'package:p3pch4t/service.dart';
+import 'package:shared_preferences/shared_preferences.dart';
 
-class LandingPage extends StatelessWidget {
+class LandingPage extends StatefulWidget {
   const LandingPage({Key? key}) : super(key: key);
 
+  @override
+  State<LandingPage> createState() => _LandingPageState();
+}
+
+class _LandingPageState extends State<LandingPage> {
+  bool isLoading = false;
+
   @override
   Widget build(BuildContext context) {
-    return const Scaffold();
+    if (isLoading) return const LoadingPlaceholder();
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text("Welcome to p3pch4t!"),
+      ),
+      body: Column(
+        children: [
+          const Text("Welcome to p3pch4t."),
+          const Text("Do you have an account? If yes "
+              "press restore below, otherwise Register"),
+          const Spacer(),
+          const Divider(),
+          Row(
+            children: [
+              TextButton(
+                onPressed: () {},
+                child: const Text("Restore"),
+              ),
+              const Spacer(),
+              OutlinedButton(
+                onPressed: () async {
+                  setState(() {
+                    isLoading = true;
+                  });
+                  final SharedPreferences prefs =
+                      await SharedPreferences.getInstance();
+
+                  debugPrint("generating privkey...");
+                  final privkey = await OpenPGP.generateKey(
+                      ['name <user@example.org>'], 'no_passpharse',
+                      rsaKeySize: RSAKeySize.s4096);
+                  prefs.setString("priv_key", privkey.armor());
+                  setState(() {
+                    isLoading = false;
+                  });
+                  if (!mounted) {
+                    await Future.delayed(const Duration(seconds: 1));
+                    exit(1);
+                  }
+                  Navigator.of(context).pushReplacement(
+                    MaterialPageRoute(
+                      builder: (context) => const HomePage(),
+                    ),
+                  );
+                },
+                child: const Text("Register"),
+              )
+            ],
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class LoginPage extends StatefulWidget {
+  const LoginPage({Key? key}) : super(key: key);
+
+  @override
+  State<LoginPage> createState() => _LoginPageState();
+}
+
+class _LoginPageState extends State<LoginPage> {
+  final privateKeyCtrl = TextEditingController();
+  final passwordCtrl = TextEditingController();
+
+  bool isLoading = false;
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text("Login"),
+      ),
+      body: Column(
+        children: [
+          if (isLoading) const LinearProgressIndicator(),
+          Expanded(
+            child: TextField(
+              controller: privateKeyCtrl,
+              maxLines: null,
+              minLines: null,
+              decoration: const InputDecoration(
+                hintText: "Your private key",
+                border: OutlineInputBorder(),
+              ),
+            ),
+          ),
+          TextField(
+            controller: passwordCtrl,
+            maxLines: null,
+            minLines: null,
+            decoration: const InputDecoration(
+              hintText: "Your private key password",
+              border: OutlineInputBorder(),
+            ),
+          ),
+          ElevatedButton(
+            onPressed: isLoading
+                ? null
+                : () async {
+                    try {
+                      setState(() {
+                        isLoading = true;
+                      });
+                      final SharedPreferences prefs =
+                          await SharedPreferences.getInstance();
+
+                      debugPrint("loading privkey...");
+                      final privkey =
+                          await OpenPGP.readPrivateKey(privateKeyCtrl.text);
+                      prefs.setString("priv_key", privkey.armor());
+                      prefs.setString("priv_passpharse", passwordCtrl.text);
+                      setState(() {
+                        isLoading = false;
+                      });
+                      await initializeService();
+                      if (!mounted) {
+                        await Future.delayed(const Duration(seconds: 1));
+                        exit(1);
+                      }
+
+                      Navigator.of(context).pushReplacement(
+                        MaterialPageRoute(
+                          builder: (context) => const HomePage(),
+                        ),
+                      );
+                    } catch (e) {
+                      setState(() {
+                        privateKeyCtrl.text =
+                            "Failed to restore session please make sure that "
+                            "the private key is valid."
+                            "\n\n---- error ----\n\n$e";
+                      });
+                    }
+                  },
+            child: const Text("Continue"),
+          ),
+        ],
+      ),
+    );
   }
 }
diff --git i/lib/pages/webxdcfileview.dart w/lib/pages/webxdcfileview.dart
index b0fb527..d5b01f3 100644
--- i/lib/pages/webxdcfileview.dart
+++ w/lib/pages/webxdcfileview.dart
@@ -81,7 +81,7 @@ class _WebxdcFileViewState extends State<WebxdcFileView> {
     if (path == "") path = "index.html";
     switch (path) {
       case "webxdc.js" || "/webxdc.js":
-        final si = (await p3p.getSelfInfo());
+        final si = (await p3p!.getSelfInfo());
         return Response.ok('''
 console.log("[webxdc.js]: loaded native implementation on browser side");
 
diff --git i/lib/pages/webxdcfileview_android.dart w/lib/pages/webxdcfileview_android.dart
index af090e8..796cf3a 100644
--- i/lib/pages/webxdcfileview_android.dart
+++ w/lib/pages/webxdcfileview_android.dart
@@ -80,7 +80,7 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
           final jBody = json.decode(p0.message);
           if (jBody["update"]["info"] != null &&
               jBody["update"]["info"] != "") {
-            p3p.sendMessage(
+            p3p!.sendMessage(
               widget.chatroom,
               jBody["update"]["info"],
               type: MessageType.service,
@@ -100,7 +100,7 @@ class _WebxdcFileViewAndroidState extends State<WebxdcFileViewAndroid> {
           );
           final lines = await updateElm.file.readAsLines();
           await updateElm.updateContent(
-            p3p,
+            p3p!,
           );
           final jsPayload = '''
 for (let i = 0; i < window.webxdc.setUpdateListenerList.length; i++) {
@@ -197,7 +197,7 @@ window.webxdc.setUpdateListenerList[${jBody["listId"] - 1}]({
   }
 
   Future<FileStoreElement?> getUpdateElement() async {
-    final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p);
+    final elms = await widget.chatroom.fileStore.getFileStoreElement(p3p!);
     final wpath = widget.webxdcFile.path;
     final desiredPath = p.normalize((wpath.split('/')
           ..removeLast()
@@ -210,13 +210,13 @@ window.webxdc.setUpdateListenerList[${jBody["listId"] - 1}]({
       }
     }
     if (updateElm == null) {
-      updateElm = await widget.chatroom.fileStore.putFileStoreElement(p3p,
+      updateElm = await widget.chatroom.fileStore.putFileStoreElement(p3p!,
           localFile: null,
           localFileSha512sum: null,
           sizeBytes: 0,
           fileInChatPath: desiredPath);
       updateElm.shouldFetch = true;
-      await updateElm.updateContent(p3p);
+      await updateElm.updateContent(p3p!);
 
       return updateElm;
     }
diff --git i/macos/Flutter/GeneratedPluginRegistrant.swift w/macos/Flutter/GeneratedPluginRegistrant.swift
index 63f93fd..c9685b7 100644
--- i/macos/Flutter/GeneratedPluginRegistrant.swift
+++ w/macos/Flutter/GeneratedPluginRegistrant.swift
@@ -5,12 +5,14 @@
 import FlutterMacOS
 import Foundation
 
+import flutter_local_notifications
 import objectbox_flutter_libs
 import path_provider_foundation
 import shared_preferences_foundation
 import url_launcher_macos
 
 func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
+  FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin"))
   ObjectboxFlutterLibsPlugin.register(with: registry.registrar(forPlugin: "ObjectboxFlutterLibsPlugin"))
   PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
   SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
diff --git i/pubspec.lock w/pubspec.lock
index 39d0cc4..92501fd 100644
--- i/pubspec.lock
+++ w/pubspec.lock
@@ -9,6 +9,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "3.3.7"
+  args:
+    dependency: transitive
+    description:
+      name: args
+      sha256: eef6c46b622e0494a36c5a12d10d77fb4e855501a91c1b9ef9339326e58f0596
+      url: "https://pub.dev"
+    source: hosted
+    version: "2.4.2"
   async:
     dependency: transitive
     description:
@@ -81,6 +89,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "1.1.5"
+  dbus:
+    dependency: transitive
+    description:
+      name: dbus
+      sha256: "6f07cba3f7b3448d42d015bfd3d53fe12e5b36da2423f23838efc1d5fb31a263"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.7.8"
   dio:
     dependency: transitive
     description:
@@ -142,6 +158,38 @@ packages:
     description: flutter
     source: sdk
     version: "0.0.0"
+  flutter_background_service:
+    dependency: "direct main"
+    description:
+      name: flutter_background_service
+      sha256: "5ec79841c3e9f3bd1885b06c5d7502d6df415cb1665e6717792cc0e51716619f"
+      url: "https://pub.dev"
+    source: hosted
+    version: "5.0.1"
+  flutter_background_service_android:
+    dependency: transitive
+    description:
+      name: flutter_background_service_android
+      sha256: a295c7604782b3723fa356679e5b14c5e0fb694d77a7299af135364fa851ee1a
+      url: "https://pub.dev"
+    source: hosted
+    version: "6.0.1"
+  flutter_background_service_ios:
+    dependency: transitive
+    description:
+      name: flutter_background_service_ios
+      sha256: ab73657535876e16abc89e40f924df3e92ad3dee83f64d187081417e824709ed
+      url: "https://pub.dev"
+    source: hosted
+    version: "5.0.0"
+  flutter_background_service_platform_interface:
+    dependency: transitive
+    description:
+      name: flutter_background_service_platform_interface
+      sha256: cd5720ff5b051d551a4734fae16683aace779bd0425e8d3f15d84a0cdcc2d8d9
+      url: "https://pub.dev"
+    source: hosted
+    version: "5.0.0"
   flutter_lints:
     dependency: "direct dev"
     description:
@@ -150,6 +198,30 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "2.0.2"
+  flutter_local_notifications:
+    dependency: "direct main"
+    description:
+      name: flutter_local_notifications
+      sha256: "3cc40fe8c50ab8383f3e053a499f00f975636622ecdc8e20a77418ece3b1e975"
+      url: "https://pub.dev"
+    source: hosted
+    version: "15.1.0+1"
+  flutter_local_notifications_linux:
+    dependency: transitive
+    description:
+      name: flutter_local_notifications_linux
+      sha256: "33f741ef47b5f63cc7f78fe75eeeac7e19f171ff3c3df054d84c1e38bedb6a03"
+      url: "https://pub.dev"
+    source: hosted
+    version: "4.0.0+1"
+  flutter_local_notifications_platform_interface:
+    dependency: transitive
+    description:
+      name: flutter_local_notifications_platform_interface
+      sha256: "7cf643d6d5022f3baed0be777b0662cce5919c0a7b86e700299f22dc4ae660ef"
+      url: "https://pub.dev"
+    source: hosted
+    version: "7.0.0+1"
   flutter_plugin_android_lifecycle:
     dependency: transitive
     description:
@@ -168,6 +240,14 @@ packages:
     description: flutter
     source: sdk
     version: "0.0.0"
+  http:
+    dependency: "direct main"
+    description:
+      name: http
+      sha256: "759d1a329847dd0f39226c688d3e06a6b8679668e350e2891a6474f8b4bb8525"
+      url: "https://pub.dev"
+    source: hosted
+    version: "1.1.0"
   http_methods:
     dependency: transitive
     description:
@@ -359,6 +439,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "0.1.3"
+  petitparser:
+    dependency: transitive
+    description:
+      name: petitparser
+      sha256: cb3798bef7fc021ac45b308f4b51208a152792445cce0448c9a4ba5879dd8750
+      url: "https://pub.dev"
+    source: hosted
+    version: "5.4.0"
   pinenacl:
     dependency: transitive
     description:
@@ -516,6 +604,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "0.5.1"
+  timezone:
+    dependency: transitive
+    description:
+      name: timezone
+      sha256: "1cfd8ddc2d1cfd836bc93e67b9be88c3adaeca6f40a00ca999104c30693cdca0"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.9.2"
   typed_data:
     dependency: transitive
     description:
@@ -652,6 +748,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "1.0.2"
+  xml:
+    dependency: transitive
+    description:
+      name: xml
+      sha256: "5bc72e1e45e941d825fd7468b9b4cc3b9327942649aeb6fc5cdbf135f0a86e84"
+      url: "https://pub.dev"
+    source: hosted
+    version: "6.3.0"
 sdks:
   dart: ">=3.0.5 <4.0.0"
   flutter: ">=3.10.0"
diff --git i/pubspec.yaml w/pubspec.yaml
index 3304b34..04c31e4 100644
--- i/pubspec.yaml
+++ w/pubspec.yaml
@@ -27,6 +27,9 @@ dependencies:
   url_launcher: ^6.1.12
   objectbox: ^2.2.0
   objectbox_flutter_libs: any
+  http: ^1.1.0
+  flutter_local_notifications: ^15.1.0+1
+  flutter_background_service: ^5.0.1
 
 dev_dependencies:
   flutter_test:
@@ -34,4 +37,6 @@ dev_dependencies:
   flutter_lints: ^2.0.0
 
 flutter:
-  uses-material-design: true 
\ No newline at end of file
+  uses-material-design: true 
+  assets:
+    - assets/git-changes.md
\ No newline at end of file
diff --git i/test/widget_test.dart w/test/widget_test.dart
deleted file mode 100644
index 73a125c..0000000
--- i/test/widget_test.dart
+++ /dev/null
@@ -1,30 +0,0 @@
-// This is a basic Flutter widget test.
-//
-// To perform an interaction with a widget in your test, use the WidgetTester
-// utility in the flutter_test package. For example, you can send tap and scroll
-// gestures. You can also use WidgetTester to find child widgets in the widget
-// tree, read text, and verify that the values of widget properties are correct.
-
-import 'package:flutter/material.dart';
-import 'package:flutter_test/flutter_test.dart';
-
-import 'package:p3pch4t/main.dart';
-
-void main() {
-  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
-    // Build our app and trigger a frame.
-    await tester.pumpWidget(const MyApp());
-
-    // Verify that our counter starts at 0.
-    expect(find.text('0'), findsOneWidget);
-    expect(find.text('1'), findsNothing);
-
-    // Tap the '+' icon and trigger a frame.
-    await tester.tap(find.byIcon(Icons.add));
-    await tester.pump();
-
-    // Verify that our counter has incremented.
-    expect(find.text('0'), findsNothing);
-    expect(find.text('1'), findsOneWidget);
-  });
-}
no changes added to commit (use "git add" and/or "git commit -a")
