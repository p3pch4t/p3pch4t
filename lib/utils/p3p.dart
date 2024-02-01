import 'dart:io';

import 'package:p3p/p3p.dart';
import 'package:p3pch4t/platform_interface.dart';
import 'package:p3pch4t/switch_platform.dart';
import 'package:path/path.dart' as p;

Future<P3p> getPlatformP3p() async {
  return switch (getPlatform()) {
    OS.android => await getP3p(
        p.join(
          (await getAndroidNativeLibraryDirectory()).path,
          'libp3pgo.so',
        ),
      ),
    OS.linux => await getP3p(
        File('/home/user/go/src/git.mrcyjanek.net/p3pch4t/p3pgo/build/api_host.so')
                .existsSync()
            ? '/home/user/go/src/git.mrcyjanek.net/p3pch4t/p3pgo/build/api_host.so'
            : 'lib/libp3pgo.so',
      ),
    OS.windows => await getP3p('../p3pgo/build/api_host.dll'),
    _ => throw UnimplementedError('p3p is not implemented')
  };
}
