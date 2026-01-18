import 'package:flutter/material.dart';
import 'package:frontend/pages/startup_page.dart';
import 'package:media_kit/media_kit.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MediaApp());

}


class MediaApp extends StatelessWidget {
  const MediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartupPage(),
    );
  }
}
