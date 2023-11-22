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
  Iterable<UserInfo> users = [];

  @override
  void initState() {
    loadUsers();
    super.initState();
  }

  Future<void> loadUsers() async {
    final value = p3p.getAllUserInfo();
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
                final ui = users.elementAt(index);
                return Card(
                  child: ListTile(
                    onTap: () async {
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ChatPage(
                            userInfo: ui,
                          ),
                        ),
                      );
                      await loadUsers();
                    },
                    onLongPress: () async {
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) {
                            return UserInfoPage(userInfo: ui);
                          },
                        ),
                      );
                    },
                    title: Text('$index. ${ui.name}'),
                    subtitle: Text(ui.publicKey.fingerprint),
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
