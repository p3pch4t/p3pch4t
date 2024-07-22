import 'package:dart_pg/dart_pg.dart';
import 'package:p3pch4t/helpers/prefs.dart';

const passpharse = "null";

Future<void> GenPGP(String name, String email) async {
  Stopwatch stopwatch = Stopwatch()..start();
  
  print("generating....");

  try {
    var privkey = await OpenPGP.generateKey(
      ["$name <$email>"],
      passpharse);
    print(privkey.toPublic.armor());
    print("${stopwatch.elapsed.inMilliseconds} ms");
    prefs.setString("privkey", privkey.armor());
  } catch (e) {
    print(e.toString());
  }
}
