// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssmdc/ssmdc.dart';
import 'package:uuid/uuid.dart';

class GroupsManager extends StatefulWidget {
  const GroupsManager({super.key});

  @override
  State<GroupsManager> createState() => _GroupsManagerState();
}

class _GroupsManagerState extends State<GroupsManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: ssmdcInstances.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              '$index. ${ssmdcInstances[index].p3p.privateKey.fingerprint}',
            ),
            subtitle: SelectableText(
              ssmdcInstances[index].p3p.privateKey.toPublic.armor(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final uuid = const Uuid().v4();
          final ssmdc = await P3pSSMDC.createGroup(
            '${p3p!.fileStorePath}/ssmdc-$uuid',
            scheduleTasks: true,
            listen: true,
          );
          ssmdcInstances.add(ssmdc);
          final prefs = await SharedPreferences.getInstance();
          final groups = prefs.getStringList('groups') ?? [];
          // ignore: cascade_invocations
          groups.add(uuid);
          await prefs.setStringList('groups', groups);
        },
      ),
    );
  }
}
