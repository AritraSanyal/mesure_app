import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.navy,
  ));

  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = [];
  }

  runApp(const MesureApp());
}

class MesureApp extends StatelessWidget {
  const MesureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mesure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomeScreen(cameras: cameras),
    );
  }
}
