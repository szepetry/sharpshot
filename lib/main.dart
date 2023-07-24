import 'package:flutter/material.dart';
import 'package:sharpshot/screens/target_game.dart';
import 'screens/camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.level = Level.debug;
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}


class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TargetGame(camera: camera),
    );
  }
}