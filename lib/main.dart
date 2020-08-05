import 'dart:js_util';

import 'package:flutter/material.dart';
import 'package:flutter_myapp/src/eth_sig_util.dart';
import 'package:flutter_myapp/src/meta_mask.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Ethereum Messenger'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key) {
    metaMaskSupport = MetaMaskSupport();
  }

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  MetaMaskSupport metaMaskSupport;
  String encryptionPublicKey;
  String message;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _wallet;
  final targetEthereumAccountController = TextEditingController();
  final messageController =
      TextEditingController(text: "Lorem ipsum dolor sit amet consectetuer");

  @override
  void initState() {
    super.initState();
    widget.message = messageController.text;
    messageController.addListener(() {
      widget.message = messageController.text;
    });
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
          .then((account) => setState(() {
                _wallet = account;
                targetEthereumAccountController.text = _wallet;
              }));
    }
  }

  // https://github.com/MetaMask/metamask-extension/pull/7831/files
  // https://github.com/logvik/test-dapp/blob/master/src/index.js
  // https://github.com/ethereum/EIPs/pull/1098
  // https://github.com/MetaMask/eth-json-rpc-middleware/commit/9464aa2085c63b43f1e5ed569bd08b0697c53d39
  // https://docs.metamask.io/guide/rpc-api.html#other-rpc-methods
  void _encrypt() {
    _encryptionPublicKey().then((value) {
      Map payload = Map();
      payload["data"] = widget.message;
      String encryptedMessage = sigUtilEncryptMessage(
          value, jsify(payload), 'x25519-xsalsa20-poly1305');
      print(encryptedMessage);
    });
  }

  Future<String> _encryptionPublicKey() {
    if (widget.encryptionPublicKey != null) {
      return Future.value(widget.encryptionPublicKey);
    } else if (widget.metaMaskSupport.isMetaMask) {
      //      widget.metaMaskSupport
      //          .clientVersion()
      //          .then((value) => print('clientVersion: ${value}'));
      return widget.metaMaskSupport.getEncryptionPublicKey().then((result) {
        widget.encryptionPublicKey = result;
        print('encryptionPublicKey: ${result}');
      }).catchError((error) {
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
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
                if (_wallet == null || _wallet == "") {
                  if (widget.metaMaskSupport.isMetaMask) {
                    return "Connect to MetaMask";
                  } else {
                    return "MetaMask is not available";
                  }
                } else {
                  return "Wallet: $_wallet";
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
