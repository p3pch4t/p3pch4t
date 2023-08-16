import 'package:flutter/material.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/pages/adduser.dart';
import 'package:p3pch4t/pages/chatpage.dart';
import 'package:p3pch4t/pages/settings.dart';
import 'package:p3pch4t/pages/userinfosettings.dart';
import 'package:p3pch4t/pages/widgets/versionwidget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<UserInfo> users = [];

  @override
  void initState() {
    loadUsers();
    loadEventCallback();
    super.initState();
  }

  @override
  void dispose() {
    p3p!.onEventCallback.removeAt(_onEventCallbackIndex);
    super.dispose();
  }

  int _onEventCallbackIndex = -1;

  void loadEventCallback() {
    p3p!.onEventCallback.add(_eventCallback);
    setState(() {
      _onEventCallbackIndex = p3p!.onEventCallback.length - 1;
    });
  }

  Future<bool> _eventCallback(P3p p3p, Event evt) async {
    if (evt.eventType != EventType.introduce) return false;
    loadUsers();
    Future.delayed(Duration.zero).then((value) => loadUsers());
    Future.delayed(const Duration(seconds: 1)).then((value) => loadUsers());
    // Why three times? Because I have no damn idea
    // when will the event finish processing...
    // I'll address that.. at some point.
    return false;
  }

  void loadUsers() async {
    final value = await p3p!.getUsers();
    setState(() {
      users = value;
    });
  }

  bool updateAvailable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("p3pch4t"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: Column(
        children: [
          const VersionWidget(),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            userInfo: p3p!.getUserInfo(
                              users[index].publicKey.fingerprint,
                            )!,
                          ),
                        ),
                      );
                      loadUsers();
                    },
                    onLongPress: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return UserInfoPage(
                              userInfo: p3p!.getUserInfo(
                                users[index].publicKey.fingerprint,
                              )!,
                            );
                          },
                        ),
                      );
                    },
                    title: Text("$index. ${users[index].name}"),
                    subtitle: Text(users[index].publicKey.fingerprint),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddUserPage(),
            ),
          );
          loadUsers();
        },
      ),
    );
  }
}
