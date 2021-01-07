import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:language_pickers/languages.dart';
import 'package:language_pickers/language_pickers.dart';
import 'package:translator/translator.dart';

import 'ScannerUtils.dart';
import 'TextDetectorPainterRealTime.dart';

class CameraScreenRealTime extends StatefulWidget {
  @override
  _CameraScreenRealTimeState createState() => _CameraScreenRealTimeState();
}

class _CameraScreenRealTimeState extends State<CameraScreenRealTime> {
  bool _isDetecting = false;
  bool loading = true;
  String translatedText = '';

  Language _selectedLanguage = LanguagePickerUtils.getLanguageByIsoCode('en');

  VisionText _textScanResults;

  CameraLensDirection _direction = CameraLensDirection.back;

  CameraController _camera;

  final translator = GoogleTranslator();

  final TextRecognizer _textRecognizer =
      FirebaseVision.instance.cloudTextRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void getWords(VisionText scanResults) {
    this.setState(() {
      loading = true;
    });
    _translateText(scanResults.text, _selectedLanguage);
  }

  void _translateText(str, lan) async {
    var translation = await translator.translate(str, to: lan);

    this.setState(() {
      translatedText = translation.text;
      loading = false;
    });
  }

  Widget _buildDialogItem(Language language) => Row(
        children: <Widget>[
          Text(language.name),
          SizedBox(width: 8.0),
          Flexible(child: Text("(${language.isoCode})"))
        ],
      );

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

  void _initializeCamera() async {
    final CameraDescription description =
        await ScannerUtils.getCamera(_direction);

    _camera = CameraController(
      description,
      ResolutionPreset.high,
    );

    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      setState(() {
        _isDetecting = true;
      });
      ScannerUtils.detect(
        image: image,
        detectInImage: _getDetectionMethod(),
        imageRotation: description.sensorOrientation,
      ).then(
        (results) {
          setState(() {
            if (results != null) {
              setState(() {
                _textScanResults = results;
              });
            }
          });
        },
      ).whenComplete(() => _isDetecting = false);
    });
  }

  Future<VisionText> Function(FirebaseVisionImage image) _getDetectionMethod() {
    return _textRecognizer.processImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TranslateMate'),
        actions: [
          FlatButton.icon(
              onPressed: _openLanguagePickerDialog,
              icon: Icon(Icons.compare_arrows, color: Colors.white),
              label: Text(_selectedLanguage.isoCode.toUpperCase(),
                  style: TextStyle(color: Colors.white)))
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _camera == null
              ? Container(
                  color: Colors.black,
                )
              : Container(
                  height: MediaQuery.of(context).size.height - 150,
                  child: CameraPreview(_camera)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: loading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Column(
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
                            height: 60,
                            child: SingleChildScrollView(
                              child: Text(
                                translatedText,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          _buildResults(_textScanResults),
        ],
      ),
    );
  }

  Widget _buildResults(VisionText scanResults) {
    CustomPainter painter;
    if (scanResults != null) {
      final Size imageSize = Size(
        _camera.value.previewSize.height - 100,
        _camera.value.previewSize.width,
      );
      painter = TextDetectorPainterRealTime(imageSize, scanResults);
      getWords(scanResults);

      return CustomPaint(
        painter: painter,
      );
    } else {
      return Container();
    }
  }
}
