import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

String? _cacheDir;

class I2pCachedNetworkImage extends StatefulWidget {
  const I2pCachedNetworkImage({required this.imageUrl, super.key});
  final String imageUrl;

  @override
  // ignore: library_private_types_in_public_api
  _I2pCachedNetworkImageState createState() => _I2pCachedNetworkImageState();
}

class _I2pCachedNetworkImageState extends State<I2pCachedNetworkImage> {
  File? localFile;

  @override
  void initState() {
    prep();
    super.initState();
  }

  Future<void> prep() async {
    if (_cacheDir == null) {
      await getApplicationCacheDirectory().then((value) {
        _cacheDir = value.absolute.path;
      });
    }
    final filePath = p.join(
      _cacheDir!,
      md5.convert(utf8.encode(widget.imageUrl)).toString(),
    );
    setState(() {
      localFile = File(filePath);
    });
    if (localFile?.existsSync() ?? false == true) {
      setState(() {
        progress = 1;
      });
    }
    await download();
  }

  double? progress;

  String? error;

  Future<void> download() async {
    if (localFile?.existsSync() ?? false == true) return;
    try {
      await i2p!.dio!.download(
        widget.imageUrl,
        localFile!.path,
        onReceiveProgress: (count, total) {
          setState(() {
            progress = count / total;
          });
        },
      );
    } catch (e) {
      setState(() {
        error = e.toString();
      });
      return;
    }
    setState(() {
      progress = 1;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: SelectableText(error ?? ''),
      );
    }
    if (localFile == null || progress != 1) {
      return Center(
        child: CircularProgressIndicator(
          value: progress,
        ),
      );
    }
    if (!localFile!.existsSync()) {
      return OutlinedButton(
        onPressed: download,
        child: const Text('Load image'),
      );
    }
    return Image.file(localFile!);
  }
}
