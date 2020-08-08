import 'package:firebase/firebase.dart';
import 'package:flutter/material.dart';
import 'package:metamask_messenger/screens/home_screen.dart';

void main() {
  initializeApp(
      apiKey: "AIzaSyC9WjOvbIIzNXdQg9-Sv58_cY6WnBfsDoc",
      authDomain: "flutter-metamask.firebaseapp.com",
      databaseURL: "https://flutter-metamask.firebaseio.com",
      projectId: "flutter-metamask",
      appId: "1:223651377112:web:4a4acb8f4a4c2ebdd14cad",
      storageBucket: "flutter-metamask.appspot.com");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetaMask Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.red,
        primaryColorLight: Color(0xFFFFEFEE),
        accentColor: Color(0xFFFEF9EB),
      ),
      home:
          HomeScreen(), // TODO: https://flutter.dev/docs/cookbook/design/orientation - OrientationBuilder
    );
  }
}
