import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:p3pch4t/consts.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/pages/webxdcstore/data_model.dart';
import 'package:p3pch4t/pages/webxdcstore/home.dart';
import 'package:p3pch4t/pages/webxdcstore/read_more_text.dart';
import 'package:p3pch4t/pages/widgets/cachednetworkimage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class WebXDCDetailsPage extends StatefulWidget {
  const WebXDCDetailsPage({required this.app, super.key});

  final WebXDCApp app;

  @override
  State<WebXDCDetailsPage> createState() => _WebXDCDetailsPageState();
}

class _WebXDCDetailsPageState extends State<WebXDCDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.app.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 1,
              child: SizedBox(
                width: double.maxFinite,
                child: I2pCachedNetworkImage(
                    imageUrl: '$storeurl/${widget.app.banner}'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.app.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w200,
                    ),
              ),
            ),
            const Divider(),
            const Padding(padding: EdgeInsets.all(8)),
            ReadMoreText(
              widget.app.description,
              numLines: 5,
              readMoreText: 'Read more',
              readLessText: 'Show less',
            ),
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () {
          setState(() {
            download();
            updateProgress();
          });
        },
        child: const Text('Download'),
      ),
    );
  }

  void download() {}

  void updateProgress() {
    Timer.periodic(const Duration(milliseconds: 111), (timer) {
      if (!mounted) timer.cancel();
      return;
    });
  }
}
