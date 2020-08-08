import 'dart:js_util';

import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart' as fs;
import 'package:flutter/material.dart';
import 'package:metamask_messenger/utils/eth_sig_util.dart';
import 'package:metamask_messenger/utils/meta_mask.dart';

class PrototypePage extends StatefulWidget {
  PrototypePage({Key key, this.title}) : super(key: key) {
    fs.Firestore store = firestore();
    fs.CollectionReference publicKeysRef = store.collection('publicKeys');
    fs.CollectionReference messagesRef = store.collection('messages');

    messagesRef.onSnapshot.listen((querySnapshot) {
      querySnapshot.docChanges().forEach((change) {
        if (change.type == "added") {
          // Do something with change.doc
        }
      });
    });
  }

  final String title;
  final MetaMaskSupport metaMaskSupport = MetaMaskSupport();

  @override
  _PrototypePageState createState() => _PrototypePageState();
}

class _PrototypePageState extends State<PrototypePage> {
  String _publicKey;
  final targetEthereumAccountController = TextEditingController();
  final messageController =
      TextEditingController(text: "Lorem ipsum dolor sit amet consectetuer");

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    targetEthereumAccountController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void _connectMetaMask() {
    if (widget.metaMaskSupport.isMetaMask) {
      widget.metaMaskSupport
          .requestAccountAccess()
          .then((value) => _encryptionPublicKey())
          .then((publicKey) => setState(() {
                _publicKey = publicKey;
                targetEthereumAccountController.text = publicKey;
              }));
    }
  }

  // https://github.com/MetaMask/metamask-extension/pull/7831/files
  // https://github.com/logvik/test-dapp/blob/master/src/index.js
  // https://github.com/ethereum/EIPs/pull/1098
  // https://github.com/MetaMask/eth-json-rpc-middleware/commit/9464aa2085c63b43f1e5ed569bd08b0697c53d39
  // https://docs.metamask.io/guide/rpc-api.html#other-rpc-methods
  void _encrypt() {
    Map payload = Map();
    payload["data"] = messageController.text;
    String encryptedMessage = sigUtilEncryptMessage(
        _publicKey, jsify(payload), 'x25519-xsalsa20-poly1305');
    print(encryptedMessage);
  }

  Future<String> _encryptionPublicKey() {
    if (_publicKey != null) {
      return Future.value(_publicKey);
    } else if (widget.metaMaskSupport.isMetaMask) {
      //      widget.metaMaskSupport
      //          .clientVersion()
      //          .then((value) => print('clientVersion: ${value}'));
      return widget.metaMaskSupport
          .getEncryptionPublicKey()
          .catchError((error) {
        if (error.code == 4001) {
          // EIP-1193 userRejectedRequest error
          print('We can\'t encrypt anything without the key.');
        } else {
          print(error);
        }
      });
    } else {
      return Future.error(Exception('MetaMask is not found!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          FlatButton(
            onPressed: _connectMetaMask,
            child: Text(
              (() {
                if (_publicKey == null || _publicKey == "") {
                  if (widget.metaMaskSupport.isMetaMask) {
                    return "Connect to MetaMask";
                  } else {
                    return "MetaMask is not available";
                  }
                } else {
                  return "Account: $_publicKey";
                }
              })(),
            ),
          )
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  controller: targetEthereumAccountController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Target Ethereum Account',
                  ),
                )),
            Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Message',
                  ),
                )),
            Padding(
                padding: EdgeInsets.all(16.0),
                child: FlatButton(
                  color: Colors.blue,
                  textColor: Colors.white,
                  disabledColor: Colors.grey,
                  disabledTextColor: Colors.black,
                  padding: EdgeInsets.all(8.0),
                  splashColor: Colors.blueAccent,
                  onPressed: _encrypt,
                  child: Text(
                    "Encrypt",
                    style: TextStyle(fontSize: 20.0),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
