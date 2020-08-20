import 'package:firebase/firestore.dart';

class Message {
  final String id;
  final DocumentReference sender;
  final DocumentReference receiver;
  final String sText;
  final String rText;
  final DateTime time;
  final bool isRead;
  String _text;

  Message(this.id, this.sender, this.receiver, this.sText, this.rText,
      this.time, this.isRead);

  Message.fromDocumentSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        sender = snapshot.get("sender"),
        receiver = snapshot.get("receiver"),
        sText = snapshot.get("sText"),
        rText = snapshot.get("rText"),
        time = snapshot.get("time"),
        isRead = snapshot.get("isRead");

  Map<String, dynamic> toFireStore() {
    return {
      "sender": sender,
      "receiver": receiver,
      "sText": sText,
      "rText": rText,
      "time": time,
      "isRead": isRead,
    };
  }

  Future<String> loadDecryptedText(DocumentReference currentUser,
      Future<String> Function(String encryptedMessage) decrypt) {
    if (_text != null && 0 < _text.length) {
      return Future.value(_text);
    } else if (sender.id == currentUser.id) {
      return decrypt(sText).then((value) => _text = value);
    } else if (receiver.id == currentUser.id) {
      return decrypt(rText).then((value) => _text = value);
    } else {
      throw ArgumentError(
          'Current user has no access to the text of the message! It can\'t be decoded!');
    }
  }

  String get text => _text;
}
