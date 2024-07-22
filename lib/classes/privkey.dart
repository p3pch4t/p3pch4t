import 'package:flutter/services.dart';
import 'package:objectbox/objectbox.dart';
import 'package:dart_pg/dart_pg.dart' as pgp;
import 'package:p3pch4t/helpers/prefs.dart';

@Entity()
class PublicKey {
  PublicKey({
    required this.publicKey,
  });

  @Id()
  int id = 0;

  @Property(type: PropertyType.date)
  DateTime timeAdded = DateTime.now();

  String publicKey;

  Future<String> encryptForMe(Uint8List data) async {
    var encrypted = await pgp.OpenPGP.encrypt(
      pgp.Message.createBinaryMessage(data),
      encryptionKeys: [
        await pgp.OpenPGP.readPublicKey((await getSelfPubKey()).publicKey)
      ],
      signingKeys: [
        await pgp.OpenPGP.readPrivateKey(prefs.getString("privkey")!)
      ]
    );
    return encrypted.armor();
  }
}

Future<PublicKey> getSelfPubKey() async {
  return PublicKey(
    publicKey: (await pgp.OpenPGP.readPrivateKey(prefs.getString("privkey")!)).toPublic.armor()
  );
}
