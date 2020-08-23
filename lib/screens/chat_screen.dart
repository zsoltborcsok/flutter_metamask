import 'dart:async';

import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'package:metamask_messenger/models/message_model.dart';
import 'package:metamask_messenger/utils/firestore_util.dart';
import 'package:metamask_messenger/utils/meta_mask.dart';

// TODO: time formatting; indicate unread messages; load more messages by scrolling(?);
class ChatScreen extends StatefulWidget {
  final MetaMaskSupport metaMaskSupport;
  final DocumentSnapshot currentUser;
  final DocumentSnapshot chatPartner;

  ChatScreen(this.metaMaskSupport, this.currentUser, this.chatPartner);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();

  List<Message> messageList = [];

  @override
  void initState() {
    super.initState();

    Stream<QuerySnapshot> chatMessagesSent = firestore()
        .collection('messages')
        .where('sender', '==', widget.currentUser.ref)
        .where('receiver', '==', widget.chatPartner.ref)
        .orderBy('time', 'desc')
        .limit(50)
        .onSnapshot;
    Stream<QuerySnapshot> chatMessagesReceived = firestore()
        .collection('messages')
        .where('sender', '==', widget.chatPartner.ref)
        .where('receiver', '==', widget.currentUser.ref)
        .orderBy('time', 'desc')
        .limit(50)
        .onSnapshot;

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

  @override
  void setState(VoidCallback fn) {
    super.setState(() {
      fn();
      messageList.sort((a, b) => -a.time.compareTo(b.time));
    });
  }

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
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
        color: isMe ? Theme.of(context).accentColor : Theme.of(context).primaryColorLight,
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
            message.time.toIso8601String(),
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.0),
          GestureDetector(
            // Use FutureBuilder to 'loadDecryptedText' automatically, which caused error in MetaMask
            onTap: () {
              message
                  .loadDecryptedText(widget.currentUser.ref, widget.metaMaskSupport.getDecryptedMessage)
                  .whenComplete(() {
                if (message.receiver.id == widget.currentUser.id && !message.isRead) {
                  firestore().collection('messages').doc(message.id).update(data: {'isRead': true});
                }
                setState(() {});
              });
            },
            child: Text(
              (() {
                if (message.text == null || message.text.length == 0) {
                  return '[Tap to decrypt the message]';
                } else {
                  return message.text;
                }
              })(),
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
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
//        IconButton(
//          icon: message.isLiked
//              ? Icon(Icons.favorite)
//              : Icon(Icons.favorite_border),
//          iconSize: 30.0,
//          color: message.isLiked
//              ? Theme.of(context).primaryColor
//              : Colors.blueGrey,
//          onPressed: () {},
//        )
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
              autofocus: true,
              controller: messageController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null, // keyboardType: TextInputType.multiline
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25.0,
            color: Theme.of(context).primaryColor,
            onPressed: () {
              _createMessage();
            },
          ),
        ],
      ),
    );
  }

  _createMessage() {
    if (0 < messageController.text.length) {
      firestore()
          .collection('messages')
          .add(Message(
                  null,
                  widget.currentUser.ref,
                  widget.chatPartner.ref,
                  widget.metaMaskSupport.encryptMessage(messageController.text, unEscape(widget.currentUser.id)),
                  widget.metaMaskSupport.encryptMessage(messageController.text, unEscape(widget.chatPartner.id)),
                  DateTime.now(),
                  false)
              .toFireStore())
          .whenComplete(() => messageController.text = '');
    }
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
                    final bool isMe = message.sender.id == widget.currentUser.id;
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
