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
    p3p.getUsers().then((value) {
      setState(() {
        users = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("p3pch4t"),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              onTap: () async {
                users[index].refresh(p3p.userinfoBox);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatPage(userInfo: users[index]),
                  ),
                );
              },
              title: Text("$index. ${users[index].name}"),
              subtitle: Text(users[index].publicKey.fingerprint),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddUserPage(),
            ),
          );
        },
      ),
    );
  }
}
