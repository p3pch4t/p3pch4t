// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/adduser.dart';
import 'package:p3pch4t/pages/chatpage.dart';
import 'package:p3pch4t/pages/groupsmanager.dart';
import 'package:p3pch4t/pages/settings.dart';
import 'package:p3pch4t/pages/userinfosettings.dart';
import 'package:p3pch4t/pages/widgets/versionwidget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

  Future<bool> _eventCallback(P3p p3p, Event evt, UserInfo ui) async {
    if (evt.eventType != EventType.introduce) return false;
    await loadUsers();
    return false;
  }

  Future<void> loadUsers() async {
    final value = await p3p!.db.getAllUserInfo();
    setState(() {
      users = value;
    });
  }

  bool updateAvailable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('p3pch4t [ beta ]'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.maxFinite,
              height: 190,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ListTile(
              title: const Text('Groups'),
              leading: const Icon(Icons.people),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const GroupsManager(),
                  ),
                );
              },
            ),
          ],
        ),
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
                      final ui = await p3p!.db.getUserInfo(
                        publicKey: users[index].publicKey,
                      );
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ChatPage(
                            userInfo: ui!,
                          ),
                        ),
                      );
                      await loadUsers();
                    },
                    onLongPress: () async {
                      final ui = await p3p!.db.getUserInfo(
                        publicKey: users[index].publicKey,
                      );
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) {
                            return UserInfoPage(userInfo: ui!);
                          },
                        ),
                      );
                    },
                    title: Text('$index. ${users[index].name}'),
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
            MaterialPageRoute<void>(
              builder: (context) => const AddUserPage(),
            ),
          );
          await loadUsers();
        },
      ),
    );
  }
}
