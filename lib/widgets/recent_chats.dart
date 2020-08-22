import 'dart:collection';

import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'package:metamask_messenger/models/message_model.dart';
import 'package:metamask_messenger/screens/chat_screen.dart';
import 'package:metamask_messenger/utils/meta_mask.dart';

class RecentChats extends StatefulWidget {
  final MetaMaskSupport metaMaskSupport;
  final DocumentSnapshot currentUser;

  RecentChats(this.metaMaskSupport, this.currentUser);

  @override
  _RecentChatsState createState() => _RecentChatsState();
}

class _RecentChatsState extends State<RecentChats> {
  final HashMap<String, Message> recentChatMessages = HashMap();
  final HashMap<String, DocumentSnapshot> chatPartners = HashMap();
  List<Message> lastChatMessages = [];

  @override
  void initState() {
    super.initState();

    Stream<QuerySnapshot> recentChatMessagesSent = firestore()
        .collection('messages')
        .where('sender', '==', widget.currentUser.ref)
        .orderBy('time', 'desc')
        .limit(100)
        .onSnapshot;
    Stream<QuerySnapshot> recentChatMessagesReceived = firestore()
        .collection('messages')
        .where('receiver', '==', widget.currentUser.ref)
        .orderBy('time', 'desc')
        .limit(100)
        .onSnapshot;

    recentChatMessagesSent.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) async {
        if (change.type == "added") {
          var message = Message.fromDocumentSnapshot(change.doc);
          if (!chatPartners.containsKey(message.receiver.id)) {
            chatPartners[message.receiver.id] = await firestore().doc('/users/${message.receiver.id}').get();
          }

          if (!recentChatMessages.containsKey(message.receiver.id) ||
              0 < message.time.compareTo(recentChatMessages[message.receiver.id].time)) {
            setState(() {
              recentChatMessages[message.receiver.id] = message;
            });
          }
        }
      });
    });
    recentChatMessagesReceived.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) async {
        if (change.type == "added") {
          var message = Message.fromDocumentSnapshot(change.doc);
          if (!chatPartners.containsKey(message.sender.id)) {
            chatPartners[message.sender.id] = await firestore().doc('/users/${message.sender.id}').get();
          }

          if (!recentChatMessages.containsKey(message.sender.id) ||
              0 < message.time.compareTo(recentChatMessages[message.sender.id].time)) {
            setState(() {
              recentChatMessages[message.sender.id] = message;
            });
          }
        }
      });
    });
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(() {
      fn();
      lastChatMessages = List.from(recentChatMessages.values);
      lastChatMessages.sort((a, b) => -a.time.compareTo(b.time));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: ListView.builder(
          padding: EdgeInsets.only(top: 5.0),
          itemCount: lastChatMessages.length,
          itemBuilder: (BuildContext context, int index) {
            final Message lastChatMessage = lastChatMessages[index];
            final chatPartner = chatPartners[lastChatMessage.sender.id != widget.currentUser.id
                ? lastChatMessage.sender.id
                : lastChatMessage.receiver.id];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(widget.metaMaskSupport, widget.currentUser, chatPartner),
                ),
              ),
              child: Container(
                margin: EdgeInsets.only(top: 5.0, bottom: 5.0, right: 20.0),
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: lastChatMessage.sender.id == widget.currentUser.id || lastChatMessage.isRead
                      ? Colors.white
                      : Theme.of(context).primaryColorLight,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 35.0,
                          backgroundImage: AssetImage('assets/images/user-placeholder.jpg'),
                        ),
                        SizedBox(width: 10.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              chatPartner.get('name'),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5.0),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Text(
                                lastChatMessage.receiver.id == widget.currentUser.id
                                    ? 'Received: [Encrypted message]'
                                    : 'Sent: [Encrypted message]',
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          lastChatMessage.time.toIso8601String(),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5.0),
                        lastChatMessage.receiver.id == widget.currentUser.id && !lastChatMessage.isRead
                            ? Container(
                                width: 40.0,
                                height: 20.0,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Text(''),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
