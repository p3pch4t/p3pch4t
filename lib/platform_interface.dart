import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _platform = MethodChannel('net.mrcyjanek.p3pch4t/nativelibrarydir');

/// Get the directory in which we store binaries on Android
Future<Directory> getAndroidNativeLibraryDirectory({
  bool forceRefresh = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  var nldir =
      prefs.getString('net.mrcyjanek.net.getAndroidNativeLibraryDirectory');

  if (nldir == null || forceRefresh) {
    nldir = await _platform
        .invokeMethod<String?>('getAndroidNativeLibraryDirectory');
    if (nldir != null) {
      await prefs.setString(
        'net.mrcyjanek.net.getAndroidNativeLibraryDirectory',
        nldir,
      );
    }
  }
  if (nldir == null) return Directory('/non_existent');
  return Directory(nldir);
}
