import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metamask_messenger/utils/meta_mask.dart';
import 'package:metamask_messenger/widgets/recent_chats.dart';

class HomeScreen extends StatefulWidget {
  final MetaMaskSupport metaMaskSupport = MetaMaskSupport();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum HamburgerMenuItem { connect, register, donate }

class _HomeScreenState extends State<HomeScreen> {
  String metaMaskPublicKey;
  DocumentSnapshot currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          'MetaMask Messenger',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            color: Colors.white,
            tooltip: 'Search',
            onPressed: () {}, // TODO search user/contact to 'start chat'
          ),
          PopupMenuButton<HamburgerMenuItem>(
            icon: Icon(Icons.menu),
            color: Colors.white,
            tooltip: 'Open menu',
            onSelected: (item) {
              switch (item) {
                case HamburgerMenuItem.connect:
                  _connectToMetaMask();
                  break;

                case HamburgerMenuItem.register:
                  _registerAccount();
                  break;

                case HamburgerMenuItem.donate:
                  _donate();
                  break;

                default:
                  print("Invalid choice");
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<HamburgerMenuItem>>[
              PopupMenuItem<HamburgerMenuItem>(
                value: HamburgerMenuItem.connect,
                child: Text(
                  (() {
                    if (metaMaskPublicKey == null || metaMaskPublicKey == "") {
                      return 'Connect to MetaMask';
                    } else {
                      return 'Account: ${metaMaskPublicKey.substring(0, 16)}...';
                    }
                  })(),
                  maxLines: 1,
                ),
                enabled: metaMaskPublicKey == null || metaMaskPublicKey == "",
              ),
              PopupMenuItem<HamburgerMenuItem>(
                value: HamburgerMenuItem.register,
                child: Text((() {
                  if (currentUser == null || !currentUser.exists) {
                    return 'Register your account';
                  } else {
                    return 'Update your registration';
                  }
                })()),
                enabled: metaMaskPublicKey != null && metaMaskPublicKey != "",
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<HamburgerMenuItem>(
                value: HamburgerMenuItem.donate,
                child: Text('Donate'),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                RecentChats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _connectToMetaMask() {
    if (widget.metaMaskSupport.isMetaMask) {
      widget.metaMaskSupport
          .requestAccountAccess()
          .then((value) => _encryptionPublicKey())
          .then((publicKey) async {
        var documentSnapshot = await firestore().doc('/users/$publicKey').get();
        setState(() {
          metaMaskPublicKey = publicKey;
          currentUser = documentSnapshot;
        });
      });
    }
  }

  Future<String> _encryptionPublicKey() {
    if (metaMaskPublicKey != null) {
      return Future.value(metaMaskPublicKey);
    } else if (widget.metaMaskSupport.isMetaMask) {
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

  void _registerAccount() {
    var formKey = GlobalKey<FormState>();
    String name = '';
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Edit your registration'),
            content: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event.runtimeType == RawKeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.escape)) {
                  Navigator.of(context).pop();
                }
              },
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      initialValue: metaMaskPublicKey,
                      decoration: InputDecoration(
                          labelText: "Public key of your account:"),
                      enabled: false,
                    ),
                    TextFormField(
                      autofocus: true,
                      initialValue: currentUser.get("name"),
                      decoration: InputDecoration(labelText: "Name:"),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please provide a name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        name = value;
                      },
                    ),
                    ButtonBar(children: <Widget>[
                      FlatButton(
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          child: Text(
                            "Delete",
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed:
                              (currentUser == null || !currentUser.exists)
                                  ? null
                                  : () {
                                      _deleteRegistration();
                                      Navigator.of(context).pop();
                                    }),
                      FlatButton(
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        child: Text(
                          "Save",
                          style: TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          if (formKey.currentState.validate()) {
                            formKey.currentState.save();
                            _updateRegistration(name);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        });
  }

  _updateRegistration(String name) {
    currentUser.ref
        .set({'name': name}, SetOptions(merge: true)).then((value) async {
      var documentSnapshot = await currentUser.ref.get();
      setState(() {
        currentUser = documentSnapshot;
      });
    });
  }

  _deleteRegistration() {
    // TODO ask for acknowledge, as it deletes all the chats as well
    if (currentUser != null || currentUser.exists) {
      currentUser.ref.delete().then((value) async {
        var documentSnapshot = await currentUser.ref.get();
        setState(() {
          currentUser = documentSnapshot;
        });
      });
    }
  }

  void _donate() {
    // TODO
  }
}
