import 'package:flutter/material.dart';

import 'CameraScreen.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'TranslateMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CameraScreen());
  }
}
