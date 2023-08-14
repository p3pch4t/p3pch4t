import 'package:flutter/material.dart';
import 'package:p3p/p3p.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({
    Key? key,
    required this.userInfo,
  }) : super(key: key);

  final UserInfo userInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo.name.toString()),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SelectableText('debug info about object ${userInfo.id}\n'
                'endpoints: ${userInfo.endpoint.toList().toString()}'),
          ],
        ),
      ),
    );
  }
}
