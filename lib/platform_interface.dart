import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');

/// Get the directory in which we store binaries on Android
Future<Directory> getAndroidNativeLibraryDirectory({
  bool forceRefresh = false,
}) async {
  if (!Platform.isAndroid) {
    return Directory('/non_existent/you_are_not_android');
  }
  var state = 'prefs';
  final prefs = await SharedPreferences.getInstance();
  var nldir =
      prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');

  if (nldir == null || forceRefresh) {
    state = 'firstif';
    nldir = await _platform
        .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
    if (nldir != null) {
      state = 'secondif';
      await prefs.setString(
        'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
        nldir,
      );
    }
  }
  if (nldir == null) return Directory('/non_existent/$state');
  return Directory(nldir);
}
