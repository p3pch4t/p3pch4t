// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:async/async.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:p3pch4t/pages/webxdcstore/data_model.dart';
import 'package:p3pch4t/pages/webxdcstore/home.dart';
import 'package:p3pch4t/service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> downloadWebXDC(WebXDCApp app, String release) async {
  final relInfo = app.releases[release];

  if (relInfo == null) {
    throw Exception(
      "given release ($release) doesn't exist in app ${app.name} [${app.uniqueId}]",
    );
  }

  final f = await getWebXDCFile(app, release);
  if (f.existsSync()) {
    final fSha = await getFileSha512(f);
    if (fSha.toString() == relInfo.xdcSha512Sum) {
      return f;
    }
  }
  await i2p!.dio!.download('$storeurl/${relInfo.webXDCDownload}', f.path);
  final fSha = await getFileSha512(f);
  if (fSha.toString() != relInfo.xdcSha512Sum) {
    throw Exception(
      'invalis sha512, deleting file ($fSha != ${relInfo.xdcSha512Sum})',
    );
  }
  return f;
}

Future<File> getWebXDCFile(WebXDCApp app, String release) async {
  final docs = await getApplicationDocumentsDirectory();
  final webxdcdir = Directory(p.join(docs.absolute.path, 'webxdc_dl'));
  if (!webxdcdir.existsSync()) {
    webxdcdir.createSync(recursive: true);
  }
  final relInfo = app.releases[release];
  if (relInfo == null) {
    throw Exception(
      "given release ($release) doesn't exist in app ${app.name} [${app.uniqueId}]",
    );
  }

  if (!isValidSHA512(relInfo.xdcSha512Sum)) {
    throw Exception(
      'given release ($release) in app ${app.name} [${app.uniqueId}] contains malformed xdcSha512sum.',
    );
  }

  final tinySha = relInfo.xdcSha512Sum.substring(0, 16); // should be enough
  return File(p.join(webxdcdir.path, '$tinySha.xdc'));
}

bool isValidSHA512(String input) {
  // Regular expression for SHA-512 hash
  final sha512Regex = RegExp(r'^[a-fA-F0-9]{128}$');

  // Check if the input matches the SHA-512 pattern
  return sha512Regex.hasMatch(input);
}

Future<Digest> getFileSha512(File file) async {
  final reader = ChunkedStreamReader(file.openRead());
  const chunkSize = 4096;
  final output = AccumulatorSink<Digest>();
  final input = sha512.startChunkedConversion(output);

  try {
    while (true) {
      final chunk = await reader.readChunk(chunkSize);
      if (chunk.isEmpty) {
        // indicate end of file
        break;
      }
      input.add(chunk);
    }
  } finally {
    // We always cancel the ChunkedStreamReader,
    // this ensures the underlying stream is cancelled.
    await reader.cancel();
  }

  input.close();

  return output.events.single;
}
