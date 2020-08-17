import 'dart:async';

import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'package:metamask_messenger/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final DocumentSnapshot currentUser;
  final DocumentSnapshot chatPartner;

  ChatScreen({this.currentUser, this.chatPartner});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messageList = [];

  @override
  void initState() {
    super.initState();

    Stream<QuerySnapshot> chatMessagesSent = firestore()
        .collection('messages')
        .where('sender', '==', widget.currentUser.ref)
        .where('receiver', '==', widget.chatPartner.ref)
        .orderBy('time')
        .limit(50)
        .onSnapshot;
    Stream<QuerySnapshot> chatMessagesReceived = firestore()
        .collection('messages')
        .where('sender', '==', widget.chatPartner.ref)
        .where('receiver', '==', widget.currentUser.ref)
        .orderBy('time')
        .limit(50)
        .onSnapshot;

    // TODO: need to order the messages based on the time (which has an unknown type yet)
    chatMessagesSent.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        if (change.type == "added") {
          setState(() {
            messageList.add(Message.fromDocumentSnapshot(change.doc));
          });
        }
      });
    });
    chatMessagesReceived.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        if (change.type == "added") {
          setState(() {
            messageList.add(Message.fromDocumentSnapshot(change.doc));
          });
        }
      });
    });
  }

  _buildMessage(Message message, bool isMe) {
    final Container msg = Container(
      margin: isMe
          ? EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              left: 80.0,
            )
          : EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
            ),
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).accentColor
            : Theme.of(context).primaryColorLight,
        borderRadius: isMe
            ? BorderRadius.only(
                topLeft: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
              )
            : BorderRadius.only(
                topRight: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message.time,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            message.sText,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (isMe) {
      return msg;
    }
    return Row(
      children: <Widget>[
        msg,
      ],
    );
  }

  _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25.0,
            color: Theme.of(context).primaryColor,
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {},
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25.0,
            color: Theme.of(context).primaryColor,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          widget.chatPartner.get('name'),
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_horiz),
            iconSize: 30.0,
            color: Colors.white,
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.only(top: 8.0),
                  itemCount: messageList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Message message = messageList[index];
                    final bool isMe =
                        message.sender.id == widget.currentUser.id;
                    return _buildMessage(message, isMe);
                  },
                ),
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }
}
