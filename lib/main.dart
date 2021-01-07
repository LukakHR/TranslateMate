import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'CameraScreen.dart';
import 'CameraScreenRealTime.dart';

// List of available cameras
List<CameraDescription> cameras = [];

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    // Retrieve the device cameras
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print(e);
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget chosenApp = null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'ML Vision',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: chosenApp == null
            ? Scaffold(
                appBar: AppBar(
                  title: Text('TranslateMate'),
                ),
                body: Center(
                  child: Column(
                    children: <Widget>[
                      RaisedButton(
                        onPressed: () => this.setState(() {
                          chosenApp = CameraScreen(cameras);
                        }),
                        child: Text('Take Picture Mode'),
                      ),
                      RaisedButton(
                        onPressed: () => this.setState(() {
                          chosenApp = CameraScreenRealTime();
                        }),
                        child: Text('Real Time Mode'),
                      ),
                    ],
                  ),
                ),
              )
            : chosenApp);
  }
}
