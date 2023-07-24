import 'dart:ui';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../widgets/target_painter.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:logger/logger.dart';
// import 'package:tflite/tflite.dart';

class TargetGame extends StatefulWidget {
  final CameraDescription camera;

  TargetGame({required this.camera});
  @override
  _TargetGameState createState() => _TargetGameState();
}

class _TargetGameState extends State<TargetGame> {
  // CameraController _controller;
  // Future<void> _initializeCameraFuture;
  List<Offset> targetPositions = []; // List of target positions (coordinates)
  int score = 0;
  int maxShots = 10;
  int remainingShots = 10;
  bool isGameStarted = false;
  bool isGameEnded = false;

  late CameraController _controller;
  late Future<void> _initializeCameraFuture;

  final logger = Logger(); // Create an instance of the logger

  void someFunction() {
    logger.d('This is a debug log'); // Debug log message
    logger.i('This is an info log'); // Info log message
    logger.w('This is a warning log'); // Warning log message
    logger.e('This is an error log'); // Error log message
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/ssd_mobilenet.txt",
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeCameraFuture = _controller.initialize().then((_) {
      _controller.startImageStream((CameraImage image) {
        detectCircles(image);
      });
    });
    loadModel(); // Load the TensorFlow Lite model
  }

  void disposeTFLite() async {
    await Tflite.close();
  }

  @override
  void dispose() {
    _controller.dispose();
    disposeTFLite();
    super.dispose();
  }

  void detectCircles(CameraImage image) async {
    // Convert CameraImage to Image
    final inputImage = img.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: img.Format.bgra,
    );

    // Perform circle detection using TensorFlow Lite
    final outputImage = await runTFLite(inputImage);

    // Convert Image back to CameraImage for displaying
    final outputBytes = outputImage.getBytes(format: img.Format.bgra);
    final plane = image.planes[0];
    plane.bytes.setRange(0, outputBytes.length, outputBytes);

    // Notify Flutter to refresh the camera preview
    setState(() {});

    // If you also want to display the processed image, you can use this:
    // setState(() {
    //   _processedImage = outputImage;
    // });
  }

  Future<img.Image> runTFLite(img.Image inputImage) async {
  // Convert inputImage to a ByteBuffer
  final inputBytes = inputImage.getBytes();
  final inputBuffer = inputBytes.buffer;
  final inputUint8List = inputBuffer.asUint8List(); // Convert ByteBuffer to Uint8List
  // final inputBufferList = [inputUint8List];

  // Perform inference using the TensorFlow Lite model
  final List<dynamic>? results = await Tflite.runModelOnBinary(
    binary: inputUint8List,
    numResults: 1,
    threshold: 0.4, // Adjust the threshold for object detection confidence
  );

  // Get the output tensor containing the detected objects
  final List<dynamic> outputData = results!.isNotEmpty ? results.first : [];
  if (outputData.isEmpty) {
    // If no circles are detected, return the input image as-is
    return inputImage;
  }

  // Process the output data to retrieve circle coordinates and radius
  List<Circle> circles = [];
  for (dynamic object in outputData) {
    if (object['confidence'] > 0.4) {
      circles.add(Circle(
        object['index'],
        object['label'],
        object['confidence'],
        object['x'] * inputImage.width,
        object['y'] * inputImage.height,
        object['width'] * inputImage.width,
        object['height'] * inputImage.height,
      ));
    }
  }

  // Create a new image with the detected circles drawn on it
  final outputImage = img.copyResize(inputImage, width: inputImage.width, height: inputImage.height);
  for (var circle in circles) {
    // final center = img.DrawPoint(circle.x, circle.y, color: img.getColor(0, 255, 0), thickness: 3);
    final radius = circle.width ~/ 2; // Equivalent to line 142
    // final radius = (circle.width / 2).toInt();
    img.drawCircle(outputImage, circle.x, circle.y, radius, img.getColor(0, 255, 0));
    img.drawPixel(outputImage, circle.x, circle.y, img.getColor(0, 255, 0));
  }

  return outputImage;
}




  void startGame() {
    // Clear previous game data and initialize game variables
    setState(() {
      score = 0;
      remainingShots = maxShots;
      isGameStarted = true;
      isGameEnded = false;
    });

    // Start the timer for the game duration
    startGameTimer();
  }

  void startGameTimer() {
    // Implement timer logic to set isGameEnded to true when the game duration is over
  }

  // void handleFire() {
  //   if (!isGameStarted || isGameEnded || remainingShots <= 0) {
  //     return; // Game hasn't started, ended, or no shots left
  //   }

  //   // Implement firing logic here (you can use a button press or gesture)
  //   // Detect the shot position and check if it hits any of the target circles

  //   // If a target is hit, update the score
  //   setState(() {
  //     // Calculate score based on hit position (center or outer edges)
  //     // Increment the score accordingly
  //     score += calculateScore(hitPosition);
  //     remainingShots--; // Reduce the remaining shots count
  //     if (remainingShots <= 0) {
  //       endGame(); // All shots taken, end the game
  //     }
  //   });
  // }

  // int calculateScore(Offset hitPosition) {
  //   // Implement logic to calculate the score based on the hit position within the target circles
  //   // Return the calculated score
  //   return 100;
  // }

  void endGame() {
    // End the game and reset game variables
    setState(() {
      isGameStarted = false;
      isGameEnded = true;
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('Target Game')),
  //     body: FutureBuilder<void>(
  //       future: _initializeCameraFuture,
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.done) {
  //           return Stack(
  //             children: [
  //               CameraPreview(_controller), // Display camera feed
  //               CustomPaint(
  //                 painter:
  //                     TargetPainter(targetPositions), // Draw target circles
  //               ),
  //               if (!isGameStarted)
  //                 Center(
  //                   child: ElevatedButton(
  //                     onPressed: startGame,
  //                     child: Text('Start Game'),
  //                   ),
  //                 ),
  //               if (isGameEnded)
  //                 Center(
  //                   child: Text('Game Over\nFinal Score: $score'),
  //                 ),
  //               Positioned(
  //                 bottom: 20,
  //                 left: 20,
  //                 child: Text('Score: $score\nShots Left: $remainingShots'),
  //               ),
  //             ],
  //           );
  //         } else {
  //           return Center(child: CircularProgressIndicator());
  //         }
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Example')),
      body: FutureBuilder<void>(
        future: _initializeCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}


class Circle {
  final int index;
  final String label;
  final double confidence;
  final int x;
  final int y;
  final int width;
  final int height;

  Circle(this.index, this.label, this.confidence, this.x, this.y, this.width, this.height);
}