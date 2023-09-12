// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// Used in places when we can't render yet
class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const LinearProgressIndicator(),
    );
  }
}
