import 'package:flutter/material.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3p/p3p.dart';
import 'package:p3pch4t/pages/adduser.dart';
import 'package:p3pch4t/pages/chatpage.dart';

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
    super.initState();
  }

  void loadUsers() async {
    final value = await p3p.getUsers();
    setState(() {
      users = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("p3pch4t"),
      ),
      body: Column(
        children: [
          Card(
            child: ListTile(
              title: const Text("New version is available!"),
              subtitle: SizedBox(
                width: double.maxFinite,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("Update"),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatPage(userInfo: users[index]),
                        ),
                      );
                      loadUsers();
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
