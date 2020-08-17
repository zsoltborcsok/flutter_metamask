import 'package:firebase/firestore.dart';

class Message {
  final DocumentReference sender;
  final DocumentReference receiver;
  final String sText;
  final String rText;
  final dynamic time;
  final bool isRead;

  Message(this.sender, this.receiver, this.sText, this.rText, this.time,
      this.isRead);

  Message.fromDocumentSnapshot(DocumentSnapshot snapshot)
      : sender = snapshot.get("sender"),
        receiver = snapshot.get("receiver"),
        sText = snapshot.get("sText"),
        rText = snapshot.get("rText"),
        time = snapshot.get("time"),
        isRead = snapshot.get("isRead");
}
