import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/enchanted_orb_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure edge-to-edge transparent system navigation & status bars
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF030104),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const SerenelleDirectApp());
}

class SerenelleDirectApp extends StatelessWidget {
  const SerenelleDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Direct',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050509),
        primaryColor: const Color(0xFFB8A8E0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB8A8E0),
          secondary: Color(0xFFC89579),
          surface: Color(0xFF111018),
          background: Color(0xFF050509),
        ),
        fontFamily: 'sans-serif-light',
      ),
      home: const EnchantedOrbScreen(),
    );
  }
}
