import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:language_pickers/languages.dart';
import 'package:translator/translator.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'TextDetectorPainter.dart';

class DetailScreen extends StatefulWidget {
  final String imagePath;
  final Language _selectedLanguage;
  DetailScreen(this.imagePath, this._selectedLanguage);

  @override
  _DetailScreenState createState() =>
      new _DetailScreenState(imagePath, _selectedLanguage);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this.path, this._selectedLanguage);

  final String path;
  final Language _selectedLanguage;
  final translator = GoogleTranslator();

  Size _imageSize;
  String recognizedText = "";
  String translatedText = "";
  List<TextElement> _elements = [];
  bool loading = true;

  void _initializeVision() async {
    final File imageFile = File(path);

    if (imageFile != null) {
      await _getImageSize(imageFile);
    }

    try {
      // create Firebase image instance
      final FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromFile(imageFile);

      // create firebase text recognizer instance
      final TextRecognizer cloudTextRecognizer =
          FirebaseVision.instance.cloudTextRecognizer();

      //process image with the text recognizer
      final VisionText visionText =
          await cloudTextRecognizer.processImage(visionImage);

      for (TextBlock block in visionText.blocks) {
        for (TextLine line in block.lines) {
          recognizedText += line.text + '\n';

          // memorize line elements to create rectangles around elements
          for (TextElement element in line.elements) {
            _elements.add(element);
          }
        }
      }

      if (recognizedText == "") {
        recognizedText = "No text found";
      }

      _translate();
    } catch (error) {
      print(error);
    }
  }

  void _translateText(str, lan) async {
    var translation = await translator.translate(str, to: lan);

    this.setState(() {
      translatedText = translation.text;
    });
  }

  void _translate() async {
    await _translateText(recognizedText, _selectedLanguage.isoCode);
    this.setState(() {
      loading = false;
    });
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    // Fetching image from path
    final Image image = Image.file(imageFile);

    // Retrieving its size
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  @override
  void initState() {
    _initializeVision();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Details"),
      ),
      body: _imageSize != null
          ? Stack(
              children: <Widget>[
                Center(
                  child: Container(
                    width: double.maxFinite,
                    color: Colors.black,
                    child: CustomPaint(
                      // draw rectangles around text elements
                      foregroundPainter:
                          TextDetectorPainter(_imageSize, _elements),
                      child: AspectRatio(
                        aspectRatio: _imageSize.aspectRatio,
                        child: Image.file(
                          File(path),
                        ),
                      ),
                    ),
                  ),
                ),
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
                                    "Identified text",
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
                                      recognizedText,
                                    ),
                                  ),
                                ),
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
              ],
            )
          : Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}
