import 'dart:io';

enum OS { android, ios, macos, windows, linux, fuchsia, web, undefined }

OS getPlatform() {
  if (Platform.isAndroid) return OS.android;
  if (Platform.isFuchsia) return OS.fuchsia;
  if (Platform.isIOS) return OS.ios;
  if (Platform.isLinux) return OS.linux;
  if (Platform.isMacOS) return OS.macos;
  if (Platform.isWindows) return OS.windows;

  return OS.undefined;
}
