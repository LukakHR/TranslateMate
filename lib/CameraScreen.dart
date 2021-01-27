import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:language_pickers/languages.dart';
import 'package:language_pickers/language_pickers.dart';
import 'package:translator/translator.dart';

import 'ScannerUtils.dart';
import 'TextDetectorPainter.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // prevents multiple fireabse requests going on at the same time
  bool _isDetecting = false;

  // keeps track of the translated text
  String translatedText = '';

  // keeps track of the selected language
  Language _selectedLanguage = LanguagePickerUtils.getLanguageByIsoCode('en');

  // keeps track of the text recognition software return value
  VisionText _textScanResults;

  // gets the camera direction to be able to draw the boxes around elements properly
  CameraLensDirection _direction = CameraLensDirection.back;

  // controls the camera
  CameraController _camera;

  // translator from the translator plug in
  final translator = GoogleTranslator();

  // text recognizer used to recognize text in the cloud
  final TextRecognizer _textRecognizer =
      FirebaseVision.instance.cloudTextRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // calls the translate function for each recognized element of text
  void getWords(VisionText scanResults) {
    if (scanResults.text.length > 0) {
      _translateText(scanResults.text, _selectedLanguage.isoCode);
    }
  }

  // translates the given str to given lan
  void _translateText(str, lan) async {
    var translation = await translator.translate(str, to: lan);

    this.setState(() {
      translatedText = translation.text;
    });
  }

  // used to draw the language picker elements
  Widget _buildDialogItem(Language language) => Row(
        children: <Widget>[
          Text(language.name),
          SizedBox(width: 8.0),
          Flexible(child: Text("(${language.isoCode})"))
        ],
      );

  // opens the language picker
  void _openLanguagePickerDialog() => showDialog(
        context: context,
        builder: (context) => Theme(
            data: Theme.of(context).copyWith(primaryColor: Colors.pink),
            child: LanguagePickerDialog(
                titlePadding: EdgeInsets.all(8.0),
                searchCursorColor: Colors.blueAccent,
                searchInputDecoration: InputDecoration(hintText: 'Search...'),
                isSearchable: true,
                title: Text('Select your language'),
                onValuePicked: (Language language) => setState(() {
                      _selectedLanguage = language;
                    }),
                itemBuilder: _buildDialogItem)),
      );

  // initializes the camera and sets up an image stream to be used to recognize text
  void _initializeCamera() async {
    final CameraDescription description =
        await ScannerUtils.getCamera(_direction);

    _camera = CameraController(
      description,
      ResolutionPreset.high,
    );

    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      // checks if it's already detecting an image
      if (_isDetecting) return;

      // signals that it has started processing an image
      _isDetecting = true;

      // gets the image from the camera and detects the text with the _getDetectionMethod()
      ScannerUtils.detect(
        image: image,
        detectInImage: _getDetectionMethod(),
        imageRotation: description.sensorOrientation,
      ).then(
        (results) {
          // sets the state with the received results
          if (results != null) {
            setState(() {
              _textScanResults = results;
            });
          }
        },
      ).whenComplete(() => _isDetecting = false);
    });
  }

  // detection method for camera
  Future<VisionText> Function(FirebaseVisionImage image) _getDetectionMethod() {
    return _textRecognizer.processImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TranslateMate'),
        actions: [
          // button for opening the language picker interface
          TextButton.icon(
              onPressed: _openLanguagePickerDialog,
              icon: Icon(Icons.compare_arrows, color: Colors.white),
              label: Text(_selectedLanguage.isoCode.toUpperCase(),
                  style: TextStyle(color: Colors.white)))
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // live camera view
          _camera == null
              ? Container(
                  color: Colors.black,
                )
              : Container(
                  height: MediaQuery.of(context).size.height - 150,
                  child: CameraPreview(_camera)),
          // card for the translated text
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              color: Colors.white,
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Translated text",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        height: 80,
                        padding: EdgeInsets.only(bottom: 10),
                        child: SingleChildScrollView(
                          child: Text(
                            translatedText,
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
          ),
          // used for drawing boxes around the recognized text elements
          _buildResults(_textScanResults),
        ],
      ),
    );
  }

  // draws boxes around recognized text elements
  Widget _buildResults(VisionText scanResults) {
    CustomPainter painter;
    if (scanResults != null) {
      final Size imageSize = Size(
        _camera.value.previewSize.height - 100,
        _camera.value.previewSize.width,
      );
      painter = TextDetectorPainter(imageSize, scanResults);

      // calls the method for translating text
      getWords(scanResults);

      return CustomPaint(
        painter: painter,
      );
    } else {
      return Container();
    }
  }
}
